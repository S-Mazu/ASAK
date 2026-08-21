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
            Update-WingetApp -Id 'VideoLAN.VLC' | Should -Be 'Upgraded'
            Should -Invoke winget -Times 1 -ParameterFilter {
                $args -contains 'upgrade' -and $args -contains 'VideoLAN.VLC'
            }
        }
    }

    Context 'no applicable upgrade found (already up to date)' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = -1978335189 }
        }
        It 'returns UpToDate' {
            Update-WingetApp -Id 'VideoLAN.VLC' | Should -Be 'UpToDate'
        }
    }

    Context 'upgrade fails' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 1 }
        }
        It 'returns Failed' {
            Update-WingetApp -Id 'VideoLAN.VLC' | Should -Be 'Failed'
        }
    }

    Context '-WhatIf' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'does not call winget and returns Skipped' {
            Update-WingetApp -Id 'VideoLAN.VLC' -WhatIf | Should -Be 'Skipped'
            Should -Invoke winget -Times 0
        }
    }

    Context '-Detached, upgrade succeeds' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
        }
        It 'spawns cmd.exe with the winget upgrade command and returns Upgraded' {
            Update-WingetApp -Id 'Microsoft.PowerShell' -Detached | Should -Be 'Upgraded'
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
            Update-WingetApp -Id 'Microsoft.PowerShell' -Detached | Should -Be 'UpToDate'
        }
    }

    Context '-Detached, upgrade fails' {
        BeforeAll {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 1 } }
        }
        It 'returns Failed' {
            Update-WingetApp -Id 'Microsoft.PowerShell' -Detached | Should -Be 'Failed'
        }
    }

    Context '-Detached -WhatIf' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
        }
        It 'does not call winget or Start-Process and returns Skipped' {
            Update-WingetApp -Id 'Microsoft.PowerShell' -Detached -WhatIf | Should -Be 'Skipped'
            Should -Invoke winget -Times 0
            Should -Invoke Start-Process -Times 0
        }
    }
}
