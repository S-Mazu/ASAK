#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-InstalledApp.ps1')
}

Describe 'Get-InstalledApp' {
    Context 'Registry source' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    DisplayName    = 'Test App'
                    DisplayVersion = '1.0.0'
                    Publisher      = 'Test Publisher'
                }
            }
        }
        It 'returns apps tagged with Source Registry' {
            $Result = Get-InstalledApp -Source Registry
            $Result.Source | Should -Contain 'Registry'
            $Result[0].Name | Should -Be 'Test App'
        }
    }

    Context 'Win32_Product source' {
        BeforeAll {
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    Name    = 'CIM App'
                    Version = '2.0.0'
                    Vendor  = 'CIM Vendor'
                }
            }
        }
        It 'returns apps tagged with Source Win32_Product' {
            $Result = Get-InstalledApp -Source Win32_Product
            $Result.Source | Should -Contain 'Win32_Product'
            $Result[0].Publisher | Should -Be 'CIM Vendor'
        }
    }

    Context 'Winget source' {
        BeforeAll {
            Mock winget {
                @(
                    'Name       Id            Version   Source'
                    '----------------------------------------'
                    'Winget App WingetApp.Id  4.0.0     winget'
                )
            }
        }
        It 'parses winget list output and tags Source Winget' {
            $Result = Get-InstalledApp -Source Winget
            $Result.Source | Should -Contain 'Winget'
            $Result[0].Name | Should -Be 'Winget App'
        }
    }

    Context 'Appx source' {
        BeforeAll {
            Mock Get-AppxPackage {
                [PSCustomObject]@{
                    Name      = 'Appx App'
                    Version   = '5.0.0'
                    Publisher = 'CN=Appx Publisher'
                }
            }
        }
        It 'returns apps tagged with Source Appx' {
            $Result = Get-InstalledApp -Source Appx
            $Result.Source | Should -Contain 'Appx'
            $Result[0].Name | Should -Be 'Appx App'
        }
    }

    Context 'multiple sources' {
        BeforeAll {
            Mock Get-ItemProperty {
                [PSCustomObject]@{ DisplayName = 'Reg App'; DisplayVersion = '1.0'; Publisher = 'Pub' }
            }
            Mock Get-AppxPackage {
                [PSCustomObject]@{ Name = 'Appx App'; Version = '2.0'; Publisher = 'CN=Pub' }
            }
        }
        It 'runs every requested source and tags each row' {
            $Result = Get-InstalledApp -Source @('Registry', 'Appx')
            ($Result.Source | Sort-Object -Unique) | Should -Be @('Appx', 'Registry')
        }
    }
}
