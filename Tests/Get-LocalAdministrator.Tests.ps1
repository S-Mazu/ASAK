#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-LocalAdministrator.ps1')
}

Describe 'Get-LocalAdministrator' {
    Context 'the group holds resolved and orphaned members' {
        BeforeAll {
            Mock Get-LocalGroupMember {
                [PSCustomObject]@{
                    Name            = 'AzureAD\StefanMazur'
                    SID             = [PSCustomObject]@{ Value = 'S-1-12-1-111' }
                    ObjectClass     = 'Benutzer'
                    PrincipalSource = 'AzureAD'
                }
                [PSCustomObject]@{
                    Name            = 'S-1-12-1-2369282296-1158250487-3105551530-2209915355'
                    SID             = [PSCustomObject]@{ Value = 'S-1-12-1-2369282296-1158250487-3105551530-2209915355' }
                    ObjectClass     = 'Andere'
                    PrincipalSource = 'AzureAD'
                }
            }
        }
        It 'queries the group by its well-known SID, not by name' {
            Get-LocalAdministrator | Out-Null
            Should -Invoke Get-LocalGroupMember -Times 1 -ParameterFilter { $SID -eq 'S-1-5-32-544' }
        }
        It 'returns one row per member' {
            $Result = @(Get-LocalAdministrator)
            $Result.Count | Should -Be 2
            $Result[0].Name | Should -Be 'AzureAD\StefanMazur'
            $Result[0].Sid | Should -Be 'S-1-12-1-111'
        }
        It 'flags a member whose name is still a raw SID' {
            $Result = @(Get-LocalAdministrator)
            $Result[0].IsUnresolved | Should -BeFalse
            $Result[1].IsUnresolved | Should -BeTrue
        }
    }

    Context 'the group is empty' {
        BeforeAll {
            Mock Get-LocalGroupMember { }
        }
        It 'returns nothing' {
            @(Get-LocalAdministrator).Count | Should -Be 0
        }
    }
}
