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
        It 'invokes winget upgrade with the given id and returns true' {
            Update-WingetApp -Id 'VideoLAN.VLC' | Should -BeTrue
            Should -Invoke winget -Times 1 -ParameterFilter {
                $args -contains 'upgrade' -and $args -contains 'VideoLAN.VLC'
            }
        }
    }

    Context 'upgrade fails' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 1 }
        }
        It 'returns false' {
            Update-WingetApp -Id 'VideoLAN.VLC' | Should -BeFalse
        }
    }

    Context '-WhatIf' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'does not call winget' {
            Update-WingetApp -Id 'VideoLAN.VLC' -WhatIf
            Should -Invoke winget -Times 0
        }
    }
}
