#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-RegistryValue.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-IntuneEnrollment.ps1')
}

Describe 'Get-IntuneEnrollment' {
    Context 'an Intune-enrolled machine' {
        BeforeAll {
            Mock Get-ChildItem {
                [PSCustomObject]@{ PSChildName = 'SCCM-BRIDGE'; PSPath = 'HKLM:\Enrollments\SCCM-BRIDGE' }
                [PSCustomObject]@{ PSChildName = 'EMPTY-KEY'; PSPath = 'HKLM:\Enrollments\EMPTY-KEY' }
                [PSCustomObject]@{ PSChildName = '2C861BCB'; PSPath = 'HKLM:\Enrollments\2C861BCB' }
            } -ParameterFilter { $Path -like 'HKLM:*Enrollments' }
            Mock Get-ChildItem { } -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }

            Mock Get-RegistryValue { 'WMI_Bridge_SCCM_Server' } -ParameterFilter { $Path -like '*SCCM-BRIDGE' -and $Name -eq 'ProviderID' }
            Mock Get-RegistryValue { 1 } -ParameterFilter { $Path -like '*SCCM-BRIDGE' -and $Name -eq 'EnrollmentState' }
            Mock Get-RegistryValue { 'MS DM Server' } -ParameterFilter { $Path -like '*2C861BCB' -and $Name -eq 'ProviderID' }
            Mock Get-RegistryValue { 1 } -ParameterFilter { $Path -like '*2C861BCB' -and $Name -eq 'EnrollmentState' }
            Mock Get-RegistryValue { 's.mazur@example.com' } -ParameterFilter { $Path -like '*2C861BCB' -and $Name -eq 'UPN' }
            Mock Get-RegistryValue { 0 } -ParameterFilter { $Path -like '*2C861BCB' -and $Name -eq 'EnrollmentType' }
            Mock Get-RegistryValue { 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc' } -ParameterFilter { $Path -like '*2C861BCB' -and $Name -eq 'DiscoveryServiceFullURL' }
            # Every other key/value combination, EMPTY-KEY included, has nothing to return.
            Mock Get-RegistryValue { }
        }
        It 'picks the MS DM Server enrollment and ignores the SCCM WMI bridge key' {
            $Result = Get-IntuneEnrollment
            $Result.Enrolled | Should -BeTrue
            $Result.EnrollmentId | Should -Be '2C861BCB'
        }
        It 'returns the enrolled user and the discovery URL' {
            $Result = Get-IntuneEnrollment
            $Result.Upn | Should -Be 's.mazur@example.com'
            $Result.DiscoveryUrl | Should -Match 'manage\.microsoft\.com'
        }
        It 'tolerates a key that carries none of the values' {
            { Get-IntuneEnrollment } | Should -Not -Throw
        }
    }

    Context 'no MDM enrollment present' {
        BeforeAll {
            Mock Get-ChildItem {
                [PSCustomObject]@{ PSChildName = 'LOCAL'; PSPath = 'HKLM:\Enrollments\LOCAL' }
            } -ParameterFilter { $Path -like 'HKLM:*Enrollments' }
            Mock Get-ChildItem { } -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
            Mock Get-RegistryValue { 'Local Authority' } -ParameterFilter { $Name -eq 'ProviderID' }
            Mock Get-RegistryValue { 1 } -ParameterFilter { $Name -eq 'EnrollmentState' }
            Mock Get-RegistryValue { }
        }
        It 'reports Enrolled false without failing' {
            $Result = Get-IntuneEnrollment
            $Result.Enrolled | Should -BeFalse
            $Result.Upn | Should -BeNullOrEmpty
        }
    }

    Context 'the MDM device certificate is readable' {
        BeforeAll {
            Mock Get-ChildItem {
                [PSCustomObject]@{ PSChildName = '2C861BCB'; PSPath = 'HKLM:\Enrollments\2C861BCB' }
            } -ParameterFilter { $Path -like 'HKLM:*Enrollments' }
            Mock Get-ChildItem {
                [PSCustomObject]@{ Issuer = 'CN=Microsoft Intune MDM Device CA'; Thumbprint = 'ABC123'; NotAfter = [datetime]'2027-01-01' }
                [PSCustomObject]@{ Issuer = 'CN=Some Other CA'; Thumbprint = 'DEF456'; NotAfter = [datetime]'2030-01-01' }
            } -ParameterFilter { $Path -eq 'Cert:\LocalMachine\My' }
            Mock Get-RegistryValue { 'MS DM Server' } -ParameterFilter { $Name -eq 'ProviderID' }
            Mock Get-RegistryValue { 1 } -ParameterFilter { $Name -eq 'EnrollmentState' }
            Mock Get-RegistryValue { }
        }
        It 'selects the Intune-issued certificate, not any other' {
            $Result = Get-IntuneEnrollment
            $Result.MdmCertThumbprint | Should -Be 'ABC123'
            $Result.MdmCertNotAfter | Should -Be ([datetime]'2027-01-01')
        }
    }
}
