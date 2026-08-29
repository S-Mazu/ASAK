#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-RegistryValue.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-AutopilotHardwareHash.ps1')
}

Describe 'Get-AutopilotHardwareHash' {
    Context 'an elevated session on a supported machine' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ DeviceHardwareData = 'T0AAAAEAAAB...' } } -ParameterFilter { $ClassName -eq 'MDM_DevDetail_Ext01' }
            Mock Get-CimInstance { [PSCustomObject]@{ SerialNumber = 'PF3ABCDE' } } -ParameterFilter { $ClassName -eq 'Win32_BIOS' }
            Mock Get-RegistryValue { '00342-55376-12406-AAOEM' }
        }
        It 'returns exactly the three columns the Intune import expects' {
            $Result = Get-AutopilotHardwareHash
            $Result.PSObject.Properties.Name | Should -Be @('Device Serial Number', 'Windows Product ID', 'Hardware Hash')
        }
        It 'fills each column from its own source' {
            $Result = Get-AutopilotHardwareHash
            $Result.'Device Serial Number' | Should -Be 'PF3ABCDE'
            $Result.'Windows Product ID' | Should -Be '00342-55376-12406-AAOEM'
            $Result.'Hardware Hash' | Should -Be 'T0AAAAEAAAB...'
        }
    }

    Context 'the hardware data is not readable' {
        BeforeAll {
            Mock Get-CimInstance { throw 'Zugriff verweigert.' } -ParameterFilter { $ClassName -eq 'MDM_DevDetail_Ext01' }
        }
        It 'throws a message naming the elevation requirement' {
            { Get-AutopilotHardwareHash } | Should -Throw '*elevated session*'
        }
    }
}
