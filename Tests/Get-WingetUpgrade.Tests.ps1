#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-WingetUpgrade.ps1')

    # Columns must be built with a real fixed-width layout: at least two spaces
    # between every header word, and each data value starting at the same
    # character offset as its header word - otherwise the shared word-boundary
    # regex (single-space-tolerant) merges adjacent header words into one
    # "column", which is not how real winget output is laid out.
    function Format-WingetTableLine {
        param([string[]]$Value, [int]$Width = 14)
        -join ($Value | ForEach-Object { $_.PadRight($Width) })
    }
}

Describe 'Get-WingetUpgrade' {
    Context 'English header, upgrades available' {
        BeforeAll {
            $HeaderLine = Format-WingetTableLine 'Name', 'Id', 'Version', 'Available', 'Source'
            $DataLine = Format-WingetTableLine 'Winget App', 'WingetApp.Id', '4.0.0', '4.1.0', 'winget'
            Mock winget { @($HeaderLine, ('-' * 70), $DataLine) }
        }
        It 'returns Name/Id/Version/Available' {
            $Result = Get-WingetUpgrade
            $Result.Count | Should -Be 1
            $Result[0].Name | Should -Be 'Winget App'
            $Result[0].Id | Should -Be 'WingetApp.Id'
            $Result[0].Version | Should -Be '4.0.0'
            $Result[0].Available | Should -Be '4.1.0'
        }
    }

    Context 'German-locale header (Verfuegbar/Quelle)' {
        BeforeAll {
            $HeaderLine = Format-WingetTableLine 'Name', 'Id', 'Version', 'Verfuegbar', 'Quelle'
            $DataLine = Format-WingetTableLine 'Winget App', 'WingetApp.Id', '4.0.0', '4.1.0', 'winget'
            Mock winget { @($HeaderLine, ('-' * 70), $DataLine) }
        }
        It 'still resolves Available by column position, not header text' {
            (Get-WingetUpgrade).Available | Should -Be '4.1.0'
        }
    }

    Context 'trailing summary line after the data rows' {
        BeforeAll {
            $HeaderLine = Format-WingetTableLine 'Name', 'Id', 'Version', 'Available', 'Source'
            $DataLine = Format-WingetTableLine 'Winget App', 'WingetApp.Id', '4.0.0', '4.1.0', 'winget'
            Mock winget { @($HeaderLine, ('-' * 70), $DataLine, '1 upgrades available.') }
        }
        It 'excludes the summary line from the result' {
            (Get-WingetUpgrade).Count | Should -Be 1
        }
    }

    Context 'no pending upgrades' {
        BeforeAll {
            Mock winget { 'No installed package found matching input criteria.' }
        }
        It 'returns nothing' {
            Get-WingetUpgrade | Should -BeNullOrEmpty
        }
    }
}
