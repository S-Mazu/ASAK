#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'ConvertFrom-WingetTable.ps1')

    # Columns must be built with a real fixed-width layout: at least two spaces
    # between every header word, and each data value starting at the same
    # character offset as its header word - otherwise the word-boundary regex
    # (single-space-tolerant) merges adjacent header words into one "column",
    # which is not how real winget output is laid out.
    function Format-WingetTableLine {
        param([string[]]$Value, [int]$Width = 14)
        -join ($Value | ForEach-Object { $_.PadRight($Width) })
    }
}

Describe 'ConvertFrom-WingetTable' {
    Context 'four-column table (no Available column)' {
        BeforeAll {
            $Script:Lines = @(
                (Format-WingetTableLine 'Name', 'Id', 'Version', 'Source')
                ('-' * 56)
                (Format-WingetTableLine 'Winget App', 'WingetApp.Id', '4.0.0', 'winget')
            )
        }
        It 'returns one row of four positional values' {
            $Rows = @(ConvertFrom-WingetTable -Line $Script:Lines)
            $Rows.Count | Should -Be 1
            $Rows[0].Count | Should -Be 4
            $Rows[0][0] | Should -Be 'Winget App'
            $Rows[0][2] | Should -Be '4.0.0'
            $Rows[0][-1] | Should -Be 'winget'
        }
    }

    Context 'five-column table (Available column present)' {
        BeforeAll {
            $Script:Lines = @(
                (Format-WingetTableLine 'Name', 'Id', 'Version', 'Available', 'Source')
                ('-' * 70)
                (Format-WingetTableLine 'Winget App', 'WingetApp.Id', '4.0.0', '4.1.0', 'winget')
            )
        }
        It 'keeps Version at index 2 and the source column last' {
            $Rows = @(ConvertFrom-WingetTable -Line $Script:Lines)
            $Rows[0].Count | Should -Be 5
            $Rows[0][2] | Should -Be '4.0.0'
            $Rows[0][3] | Should -Be '4.1.0'
            $Rows[0][-1] | Should -Be 'winget'
        }
    }

    Context 'German-locale headers (Verfuegbar/Quelle)' {
        BeforeAll {
            $Script:Lines = @(
                (Format-WingetTableLine 'Name', 'Id', 'Version', 'Verfuegbar', 'Quelle')
                ('-' * 70)
                (Format-WingetTableLine 'Winget App', 'WingetApp.Id', '4.0.0', '4.1.0', 'winget')
            )
        }
        It 'resolves fields by position, not by header text' {
            $Rows = @(ConvertFrom-WingetTable -Line $Script:Lines)
            $Rows[0][2] | Should -Be '4.0.0'
            $Rows[0][-1] | Should -Be 'winget'
        }
    }

    Context 'row shorter than the header (trailing column absent)' {
        BeforeAll {
            $Script:Lines = @(
                (Format-WingetTableLine 'Name', 'Id', 'Version', 'Source')
                ('-' * 56)
                (Format-WingetTableLine 'Local App', 'Local.Id')
            )
        }
        It 'pads missing columns with an empty string instead of dropping them' {
            $Rows = @(ConvertFrom-WingetTable -Line $Script:Lines)
            $Rows[0].Count | Should -Be 4
            $Rows[0][2] | Should -Be ''
            $Rows[0][-1] | Should -Be ''
        }
    }

    Context 'multiple data rows' {
        BeforeAll {
            $Script:Lines = @(
                (Format-WingetTableLine 'Name', 'Id', 'Version', 'Source')
                ('-' * 56)
                (Format-WingetTableLine 'App One', 'One.Id', '1.0.0', 'winget')
                ''
                (Format-WingetTableLine 'App Two', 'Two.Id', '2.0.0', 'msstore')
            )
        }
        It 'skips blank lines and keeps each row intact' {
            $Rows = @(ConvertFrom-WingetTable -Line $Script:Lines)
            $Rows.Count | Should -Be 2
            $Rows[1][0] | Should -Be 'App Two'
            $Rows[1][-1] | Should -Be 'msstore'
        }
    }

    Context 'preamble lines before the header' {
        BeforeAll {
            $Script:Lines = @(
                '   - '
                'Zugriff auf die Quelle wird ausgefuehrt...'
                (Format-WingetTableLine 'Name', 'Id', 'Version', 'Source')
                ('-' * 56)
                (Format-WingetTableLine 'Winget App', 'WingetApp.Id', '4.0.0', 'winget')
            )
        }
        It 'starts at the Name header row' {
            $Rows = @(ConvertFrom-WingetTable -Line $Script:Lines)
            $Rows.Count | Should -Be 1
            $Rows[0][0] | Should -Be 'Winget App'
        }
    }

    Context 'no header row' {
        It 'returns nothing' {
            ConvertFrom-WingetTable -Line @('No installed package found matching input criteria.') |
                Should -BeNullOrEmpty
        }
    }

    Context 'header without data rows' {
        It 'returns nothing' {
            $Lines = @((Format-WingetTableLine 'Name', 'Id', 'Version', 'Source'), ('-' * 56))
            ConvertFrom-WingetTable -Line $Lines | Should -BeNullOrEmpty
        }
    }

    Context 'empty input' {
        It 'returns nothing' {
            ConvertFrom-WingetTable -Line @() | Should -BeNullOrEmpty
        }
    }
}
