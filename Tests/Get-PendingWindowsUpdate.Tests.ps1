#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-PendingWindowsUpdate.ps1')
}

Describe 'Get-PendingWindowsUpdate' {
    Context 'updates are pending' {
        BeforeAll {
            # Stands in for the Microsoft.Update.Session COM object. $Criteria records what
            # the function asked the update searcher for, so a test can assert on it.
            $Criteria = [System.Collections.Generic.List[string]]::new()
            $Updates = @(
                [PSCustomObject]@{
                    Title                = '2026-08 Cumulative Update for Windows 11'
                    KBArticleIDs         = @('5062553')
                    MsrcSeverity         = 'Critical'
                    IsMandatory          = $true
                    InstallationBehavior = [PSCustomObject]@{ RebootBehavior = 1 }
                    MaxDownloadSize      = 786432000
                }
                [PSCustomObject]@{
                    Title                = 'Update for Microsoft Defender Antivirus'
                    KBArticleIDs         = @()
                    MsrcSeverity         = $null
                    IsMandatory          = $false
                    InstallationBehavior = [PSCustomObject]@{ RebootBehavior = 0 }
                    MaxDownloadSize      = 2097152
                }
            )
            Mock New-Object {
                # GetNewClosure captures only the local scope, so $Criteria has to be aliased
                # here before the Search body can see it. Both names hold the same list.
                $Recorder = $Criteria
                $SearchResult = [PSCustomObject]@{ Updates = $Updates }
                $Searcher = [PSCustomObject]@{}
                $Searcher | Add-Member -MemberType ScriptMethod -Name Search -Value {
                    param($Query)
                    $Recorder.Add($Query)
                    $SearchResult
                }.GetNewClosure()
                $Session = [PSCustomObject]@{}
                $Session | Add-Member -MemberType ScriptMethod -Name CreateUpdateSearcher -Value { $Searcher }.GetNewClosure()
                $Session
            } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }
        }
        It 'returns one row per pending update' {
            $Result = @(Get-PendingWindowsUpdate)
            $Result.Count | Should -Be 2
            $Result[0].Title | Should -Be '2026-08 Cumulative Update for Windows 11'
            $Result[0].Severity | Should -Be 'Critical'
        }
        It 'prefixes the KB numbers and leaves the field empty when there are none' {
            $Result = @(Get-PendingWindowsUpdate)
            $Result[0].KB | Should -Be 'KB5062553'
            $Result[1].KB | Should -BeNullOrEmpty
        }
        It 'derives RebootRequired from the installation behavior' {
            $Result = @(Get-PendingWindowsUpdate)
            $Result[0].RebootRequired | Should -BeTrue
            $Result[1].RebootRequired | Should -BeFalse
        }
        It 'reports the download size in megabytes' {
            (@(Get-PendingWindowsUpdate))[0].SizeMb | Should -Be 750
        }
        It 'searches only for uninstalled, non-hidden software updates' {
            Get-PendingWindowsUpdate | Out-Null
            $Criteria[0] | Should -Be "IsInstalled=0 AND Type='Software' AND IsHidden=0"
        }
    }

    Context 'the machine is fully patched' {
        BeforeAll {
            $Updates = @()
            Mock New-Object {
                $SearchResult = [PSCustomObject]@{ Updates = $Updates }
                $Searcher = [PSCustomObject]@{}
                $Searcher | Add-Member -MemberType ScriptMethod -Name Search -Value { $SearchResult }.GetNewClosure()
                $Session = [PSCustomObject]@{}
                $Session | Add-Member -MemberType ScriptMethod -Name CreateUpdateSearcher -Value { $Searcher }.GetNewClosure()
                $Session
            } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }
        }
        It 'returns nothing' {
            @(Get-PendingWindowsUpdate).Count | Should -Be 0
        }
    }
}
