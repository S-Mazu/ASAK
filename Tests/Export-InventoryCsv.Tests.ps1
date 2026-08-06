#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Export-InventoryCsv.ps1')
}

Describe 'Export-InventoryCsv' {
    BeforeAll {
        Mock Export-Csv { }
    }

    It 'passes NoTypeInformation, Encoding and Delimiter through to Export-Csv' {
        $Data = @([PSCustomObject]@{ Name = 'Test' })
        $Data | Export-InventoryCsv -Path 'C:\temp\out.csv' -NoTypeInformation -Encoding UTF8 -Delimiter ';'

        Should -Invoke Export-Csv -Times 1 -ParameterFilter {
            $Path -eq 'C:\temp\out.csv' -and
            $Delimiter -eq ';' -and
            $Encoding -eq [System.Text.Encoding]::UTF8 -and
            $NoTypeInformation -eq $true
        }
    }

    It 'defaults to UTF8 encoding and semicolon delimiter when not specified' {
        $Data = @([PSCustomObject]@{ Name = 'Test' })
        $Data | Export-InventoryCsv -Path 'C:\temp\out2.csv'

        Should -Invoke Export-Csv -Times 1 -ParameterFilter {
            $Encoding -eq [System.Text.Encoding]::UTF8 -and $Delimiter -eq ';'
        }
    }
}
