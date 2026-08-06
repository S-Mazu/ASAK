#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-InstalledFeature.ps1')
}

Describe 'Get-InstalledFeature' {
    Context 'Optional source' {
        BeforeAll {
            Mock Get-WindowsOptionalFeature {
                [PSCustomObject]@{
                    FeatureName = 'TestFeature'
                    State       = 'Enabled'
                }
            }
        }
        It 'returns features tagged with Source Optional' {
            $Result = Get-InstalledFeature -Source Optional
            $Result.Source | Should -Contain 'Optional'
            $Result[0].Name | Should -Be 'TestFeature'
        }
    }

    Context 'ServerManager source' {
        BeforeAll {
            # ServerManager isn't installed on this (client) machine, so Get-WindowsFeature
            # doesn't exist to build a Mock proxy from. Stub it first so Mock has a command to attach to.
            function Get-WindowsFeature { }
            Mock Import-Module { }
            Mock Get-WindowsFeature {
                [PSCustomObject]@{
                    Name         = 'Test-Role'
                    InstallState = 'Installed'
                }
            }
        }
        It 'returns features tagged with Source ServerManager' {
            $Result = Get-InstalledFeature -Source ServerManager
            $Result.Source | Should -Contain 'ServerManager'
            $Result[0].State | Should -Be 'Installed'
        }
    }
}
