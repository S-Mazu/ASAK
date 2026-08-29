#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-RegistryValue.ps1')
}

Describe 'Get-RegistryValue' {
    Context 'the value is present' {
        BeforeAll {
            Mock Get-ItemProperty { [PSCustomObject]@{ ProviderID = 'MS DM Server'; EnrollmentState = 1 } }
        }
        It 'returns the value' {
            Get-RegistryValue -Path 'HKLM:\Anything' -Name 'ProviderID' | Should -Be 'MS DM Server'
        }
    }

    Context 'the key exists but the value does not' {
        BeforeAll {
            Mock Get-ItemProperty { [PSCustomObject]@{ EnrollmentState = 1 } }
        }
        It 'returns null instead of writing an error' {
            Get-RegistryValue -Path 'HKLM:\Anything' -Name 'ProviderID' | Should -BeNullOrEmpty
        }
    }

    Context 'the key does not exist' {
        BeforeAll {
            Mock Get-ItemProperty { }
        }
        It 'returns null' {
            Get-RegistryValue -Path 'HKLM:\Missing' -Name 'ProviderID' | Should -BeNullOrEmpty
        }
    }
}
