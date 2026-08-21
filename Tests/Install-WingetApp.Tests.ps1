#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Install-WingetApp.ps1')
}

Describe 'Install-WingetApp' {
    Context 'install succeeds' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'invokes winget install with the given id and returns true' {
            Install-WingetApp -Id 'VideoLAN.VLC' | Should -BeTrue
            Should -Invoke winget -Times 1 -ParameterFilter {
                $args -contains 'install' -and $args -contains 'VideoLAN.VLC'
            }
        }
    }

    Context 'install fails' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 1 }
        }
        It 'returns false' {
            Install-WingetApp -Id 'VideoLAN.VLC' | Should -BeFalse
        }
    }

    Context '-WhatIf' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'does not call winget' {
            Install-WingetApp -Id 'VideoLAN.VLC' -WhatIf
            Should -Invoke winget -Times 0
        }
    }
}
