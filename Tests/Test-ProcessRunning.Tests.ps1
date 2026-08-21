#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Test-ProcessRunning.ps1')
}

Describe 'Test-ProcessRunning' {
    Context 'process is running' {
        BeforeAll {
            Mock Get-Process { [PSCustomObject]@{ Name = 'vlc' } }
        }
        It 'returns true' {
            Test-ProcessRunning -Name 'vlc' | Should -BeTrue
        }
    }

    Context 'process is not running' {
        BeforeAll {
            Mock Get-Process { }
        }
        It 'returns false' {
            Test-ProcessRunning -Name 'vlc' | Should -BeFalse
        }
    }
}
