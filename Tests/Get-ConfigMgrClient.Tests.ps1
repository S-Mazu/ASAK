#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-RegistryValue.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-ConfigMgrClient.ps1')
}

Describe 'Get-ConfigMgrClient' {
    Context 'the ConfigMgr client is installed' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ ClientVersion = '5.00.9128.1006' } } -ParameterFilter { $ClassName -eq 'SMS_Client' }
            Mock Get-CimInstance {
                [PSCustomObject]@{ Name = 'SMS:P01'; CurrentManagementPoint = 'mp.example.com' }
            } -ParameterFilter { $ClassName -eq 'SMS_Authority' }
            Mock Get-RegistryValue { 1 }
        }
        It 'reports the client version and strips the SMS: prefix from the site code' {
            $Result = Get-ConfigMgrClient
            $Result.Installed | Should -BeTrue
            $Result.ClientVersion | Should -Be '5.00.9128.1006'
            $Result.SiteCode | Should -Be 'P01'
            $Result.ManagementPoint | Should -Be 'mp.example.com'
        }
    }

    Context 'root\ccm is absent - no client installed' {
        BeforeAll {
            # The namespace does not exist, so Get-CimInstance returns nothing at all.
            Mock Get-CimInstance { }
            Mock Get-RegistryValue { }
        }
        It 'reports Installed false rather than throwing' {
            $Result = Get-ConfigMgrClient
            $Result.Installed | Should -BeFalse
            $Result.ClientVersion | Should -BeNullOrEmpty
            $Result.SiteCode | Should -BeNullOrEmpty
        }
        It 'does not consult the registry at all' {
            Get-ConfigMgrClient | Out-Null
            Should -Invoke Get-RegistryValue -Times 0
        }
    }

    Context 'a client without co-management configured' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ ClientVersion = '5.00.9128.1006' } } -ParameterFilter { $ClassName -eq 'SMS_Client' }
            Mock Get-CimInstance { } -ParameterFilter { $ClassName -eq 'SMS_Authority' }
            Mock Get-RegistryValue { }
        }
        It 'tolerates the missing CoManagementFlags key and the missing authority' {
            $Result = Get-ConfigMgrClient
            $Result.Installed | Should -BeTrue
            $Result.CoManagementFlags | Should -BeNullOrEmpty
            $Result.ManagementPoint | Should -BeNullOrEmpty
        }
    }
}
