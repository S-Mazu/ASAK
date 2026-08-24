#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Update-WingetApp.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Invoke-WingetBulkUpgrade.ps1')
}

Describe 'Invoke-WingetBulkUpgrade' {
    Context 'upgrades every app in the batch' {
        BeforeAll {
            Mock Update-WingetApp { 'Upgraded' }
        }
        It 'calls Update-WingetApp once per app and reports its result' {
            $Apps = @(
                [PSCustomObject]@{ Name = 'VLC Player'; Id = 'VideoLAN.VLC'; DetachedUpgrade = $false }
                [PSCustomObject]@{ Name = 'Gimp'; Id = 'GIMP.GIMP'; DetachedUpgrade = $false }
            )
            $Result = Invoke-WingetBulkUpgrade -App $Apps
            $Result.Count | Should -Be 2
            $Result[0].Result | Should -Be 'Upgraded'
            Should -Invoke Update-WingetApp -Times 2
        }
    }

    Context 'respects DetachedUpgrade per app' {
        BeforeAll {
            Mock Update-WingetApp { 'Upgraded' }
        }
        It 'passes -Detached only for apps flagged DetachedUpgrade' {
            $Apps = @(
                [PSCustomObject]@{ Name = 'PowerShell 7'; Id = 'Microsoft.PowerShell'; DetachedUpgrade = $true }
                [PSCustomObject]@{ Name = 'VLC Player'; Id = 'VideoLAN.VLC'; DetachedUpgrade = $false }
            )
            Invoke-WingetBulkUpgrade -App $Apps | Out-Null
            Should -Invoke Update-WingetApp -Times 1 -ParameterFilter {
                $Id -eq 'Microsoft.PowerShell' -and $Detached -eq $true
            }
            Should -Invoke Update-WingetApp -Times 1 -ParameterFilter {
                $Id -eq 'VideoLAN.VLC' -and $Detached -eq $false
            }
        }
    }

    Context '-WhatIf' {
        BeforeAll {
            Mock Update-WingetApp { 'Upgraded' }
        }
        It 'does not call Update-WingetApp and reports Skipped for every app' {
            $Apps = @(
                [PSCustomObject]@{ Name = 'VLC Player'; Id = 'VideoLAN.VLC'; DetachedUpgrade = $false }
            )
            $Result = Invoke-WingetBulkUpgrade -App $Apps -WhatIf
            $Result[0].Result | Should -Be 'Skipped'
            Should -Invoke Update-WingetApp -Times 0
        }
    }
}
