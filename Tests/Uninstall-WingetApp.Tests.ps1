#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Uninstall-WingetApp.ps1')
}

Describe 'Uninstall-WingetApp' {
    Context 'uninstall succeeds' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'invokes winget uninstall with the given id and returns true' {
            Uninstall-WingetApp -Id 'VideoLAN.VLC' | Should -BeTrue
            Should -Invoke winget -Times 1 -ParameterFilter {
                $args -contains 'uninstall' -and $args -contains 'VideoLAN.VLC'
            }
        }
    }

    Context 'uninstall fails' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 1 }
        }
        It 'returns false' {
            Uninstall-WingetApp -Id 'VideoLAN.VLC' | Should -BeFalse
        }
    }

    Context '-WhatIf' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'does not call winget' {
            Uninstall-WingetApp -Id 'VideoLAN.VLC' -WhatIf
            Should -Invoke winget -Times 0
        }
    }
}
