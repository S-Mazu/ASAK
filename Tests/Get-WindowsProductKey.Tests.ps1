#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-RegistryValue.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-WindowsProductKey.ps1')
}

Describe 'Get-WindowsProductKey' {
    Context 'a licensed OEM machine' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ OA3xOriginalProductKey = 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE' } } -ParameterFilter {
                $ClassName -eq 'SoftwareLicensingService'
            }
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    Name              = 'Windows(R), Professional edition'
                    LicenseStatus     = 1
                    ProductKeyChannel = 'OEM:DM'
                    PartialProductKey = '46YW2'
                }
            } -ParameterFilter { $ClassName -eq 'SoftwareLicensingProduct' }
            Mock Get-ItemProperty { [PSCustomObject]@{ ProductId = '00342-55376-12406-AAOEM' } }
        }
        It 'returns the firmware key and the licensing detail' {
            $Result = Get-WindowsProductKey
            $Result.FirmwareProductKey | Should -Be 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE'
            $Result.PartialProductKey | Should -Be '46YW2'
            $Result.LicenseChannel | Should -Be 'OEM:DM'
            $Result.ProductId | Should -Be '00342-55376-12406-AAOEM'
        }
        It 'maps the numeric LicenseStatus to text' {
            (Get-WindowsProductKey).LicenseStatus | Should -Be 'Licensed'
        }
    }

    Context 'a machine with no firmware key' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ OA3xOriginalProductKey = '' } } -ParameterFilter {
                $ClassName -eq 'SoftwareLicensingService'
            }
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    Name              = 'Windows(R), Professional edition'
                    LicenseStatus     = 2
                    ProductKeyChannel = 'Retail'
                    PartialProductKey = 'XXXXX'
                }
            } -ParameterFilter { $ClassName -eq 'SoftwareLicensingProduct' }
            Mock Get-ItemProperty { [PSCustomObject]@{ ProductId = '00330-00000-00000-AA000' } }
        }
        It 'reports the empty key without failing' {
            $Result = Get-WindowsProductKey
            $Result.FirmwareProductKey | Should -BeNullOrEmpty
            $Result.LicenseStatus | Should -Be 'Out-of-box grace period'
        }
    }

    Context 'no Windows licensing product is reported' {
        BeforeAll {
            Mock Get-CimInstance { [PSCustomObject]@{ OA3xOriginalProductKey = '' } } -ParameterFilter {
                $ClassName -eq 'SoftwareLicensingService'
            }
            Mock Get-CimInstance { } -ParameterFilter { $ClassName -eq 'SoftwareLicensingProduct' }
            Mock Get-ItemProperty { [PSCustomObject]@{ ProductId = '' } }
        }
        It 'returns Unknown rather than throwing' {
            (Get-WindowsProductKey).LicenseStatus | Should -Be 'Unknown'
        }
    }
}
