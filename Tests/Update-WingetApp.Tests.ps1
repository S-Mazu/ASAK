#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Update-WingetApp.ps1')
}

Describe 'Update-WingetApp' {
    Context 'upgrade succeeds' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'invokes winget upgrade with the given id and returns Upgraded' {
            $Outcome = Update-WingetApp -Id 'VideoLAN.VLC'
            $Outcome.Result | Should -Be 'Upgraded'
            $Outcome.ExitCode | Should -Be 0
            Should -Invoke winget -Times 1 -ParameterFilter {
                $args -contains 'upgrade' -and $args -contains 'VideoLAN.VLC'
            }
        }
    }

    Context 'no applicable upgrade found (already up to date)' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = -1978335189 }
        }
        It 'returns UpToDate with the no-upgrade-available exit code' {
            $Outcome = Update-WingetApp -Id 'VideoLAN.VLC'
            $Outcome.Result | Should -Be 'UpToDate'
            $Outcome.ExitCode | Should -Be -1978335189
        }
    }

    Context 'upgrade fails' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 1 }
        }
        It 'returns Failed and carries the winget exit code' {
            $Outcome = Update-WingetApp -Id 'VideoLAN.VLC'
            $Outcome.Result | Should -Be 'Failed'
            $Outcome.ExitCode | Should -Be 1
        }
    }

    Context '-WhatIf' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'does not call winget and returns Skipped with no exit code' {
            $Outcome = Update-WingetApp -Id 'VideoLAN.VLC' -WhatIf
            $Outcome.Result | Should -Be 'Skipped'
            $Outcome.ExitCode | Should -BeNullOrEmpty
            Should -Invoke winget -Times 0
        }
    }

    Context '-Detached, upgrade succeeds' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
        }
        It 'spawns cmd.exe with the winget upgrade command and returns Upgraded' {
            $Outcome = Update-WingetApp -Id 'Microsoft.PowerShell' -Detached
            $Outcome.Result | Should -Be 'Upgraded'
            $Outcome.ExitCode | Should -Be 0
            Should -Invoke Start-Process -Times 1 -ParameterFilter {
                $FilePath -eq 'cmd.exe' -and
                $ArgumentList -contains 'upgrade' -and
                $ArgumentList -contains 'Microsoft.PowerShell'
            }
            Should -Invoke winget -Times 0
        }
    }

    Context '-Detached, no applicable upgrade found' {
        BeforeAll {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = -1978335189 } }
        }
        It 'returns UpToDate' {
            (Update-WingetApp -Id 'Microsoft.PowerShell' -Detached).Result | Should -Be 'UpToDate'
        }
    }

    Context '-Detached, upgrade fails' {
        BeforeAll {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } }
        }
        It 'returns Failed and carries the exit code from the spawned process' {
            $Outcome = Update-WingetApp -Id 'Microsoft.PowerShell' -Detached
            $Outcome.Result | Should -Be 'Failed'
            $Outcome.ExitCode | Should -Be 1
        }
    }

    Context '-Detached -WhatIf' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
        }
        It 'does not call winget or Start-Process and returns Skipped' {
            (Update-WingetApp -Id 'Microsoft.PowerShell' -Detached -WhatIf).Result | Should -Be 'Skipped'
            Should -Invoke winget -Times 0
            Should -Invoke Start-Process -Times 0
        }
    }
}
