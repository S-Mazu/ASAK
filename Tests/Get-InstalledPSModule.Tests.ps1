#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-InstalledPSModule.ps1')
}

Describe 'Get-InstalledPSModule' {
    BeforeAll {
        $Script:OriginalPSModulePath = $env:PSModulePath
    }
    AfterAll {
        $env:PSModulePath = $Script:OriginalPSModulePath
    }

    Context 'scope tagging' {
        BeforeAll {
            $env:PSModulePath = 'C:\Root1;C:\Root2'
            Mock Get-Module {
                [PSCustomObject]@{
                    Name       = 'Test Module'
                    Version    = '1.0.0'
                    Author     = 'Test Author'
                    ModuleBase = 'C:\Root2\TestModule\1.0.0'
                }
            }
        }
        It 'tags Source with the matching PSModulePath segment verbatim' {
            $Result = Get-InstalledPSModule -Source Module
            $Result[0].Source | Should -Be 'C:\Root2'
            $Result[0].Name | Should -Be 'Test Module'
            $Result[0].Publisher | Should -Be 'Test Author'
        }
    }

    Context 'no matching PSModulePath segment' {
        BeforeAll {
            $env:PSModulePath = 'C:\Root1;C:\Root2'
            Mock Get-Module {
                [PSCustomObject]@{
                    Name       = 'Outside Module'
                    Version    = '2.0.0'
                    Author     = 'Outside Author'
                    ModuleBase = 'D:\Outside\OutsideModule\2.0.0'
                }
            }
        }
        It 'falls back to the module''s own ModuleBase' {
            $Result = Get-InstalledPSModule -Source Module
            $Result[0].Source | Should -Be 'D:\Outside\OutsideModule\2.0.0'
        }
    }

    Context 'Package source' {
        BeforeAll {
            # Get-Package's provider-injected dynamic parameters break Pester's mock-proxy
            # generation. Stub it first so Mock builds the proxy from the plain stub instead.
            function Get-Package { }
            Mock Get-Package {
                [PSCustomObject]@{
                    Name         = 'Pkg Module'
                    Version      = '3.0.0'
                    ProviderName = 'PowerShellGet'
                }
            }
        }
        It 'returns packages tagged with Source Package' {
            $Result = Get-InstalledPSModule -Source Package
            $Result.Source | Should -Contain 'Package'
            $Result[0].Name | Should -Be 'Pkg Module'
        }
    }
}
