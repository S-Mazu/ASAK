#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Test-WingetAppInstalled.ps1')
}

Describe 'Test-WingetAppInstalled' {
    Context 'package is installed' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 0 }
        }
        It 'returns true' {
            Test-WingetAppInstalled -Id 'VideoLAN.VLC' | Should -BeTrue
        }
    }

    Context 'package is not installed' {
        BeforeAll {
            Mock winget { $global:LASTEXITCODE = 1 }
        }
        It 'returns false' {
            Test-WingetAppInstalled -Id 'VideoLAN.VLC' | Should -BeFalse
        }
    }
}
