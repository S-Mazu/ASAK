#requires -Version 7.6

function Get-InstalledApp {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Registry', 'Win32_Product', 'Package', 'Winget')]
        [string[]]$Source
    )

    foreach ($CurrentSource in $Source) {
        switch ($CurrentSource) {
            'Registry' {
                $UninstallPaths = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                )
                Get-ItemProperty -Path $UninstallPaths -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName } |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Source    = 'Registry'
                            Name      = $_.DisplayName
                            Version   = $_.DisplayVersion
                            Publisher = $_.Publisher
                        }
                    }
            }
            'Win32_Product' {
                Get-CimInstance -ClassName Win32_Product |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Source    = 'Win32_Product'
                            Name      = $_.Name
                            Version   = $_.Version
                            Publisher = $_.Vendor
                        }
                    }
            }
            'Package' {
                Get-Package -Name '*' |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Source    = 'Package'
                            Name      = $_.Name
                            Version   = $_.Version
                            Publisher = $_.ProviderName
                        }
                    }
            }
            'Winget' {
                # winget list has no structured output mode; columns are fixed-width,
                # located from the header row's word-start offsets. A winget CLI
                # format change would break this parser.
                $Lines = (& winget list --disable-interactivity 2>$null) |
                    Where-Object { $_.Trim() -ne '' }
                $HeaderIndex = 0
                while ($HeaderIndex -lt $Lines.Count -and $Lines[$HeaderIndex] -notmatch '^Name\s') {
                    $HeaderIndex++
                }
                if ($HeaderIndex -lt $Lines.Count) {
                    $HeaderLine = $Lines[$HeaderIndex]
                    $DataLines = $Lines[($HeaderIndex + 2)..($Lines.Count - 1)]
                    $ColumnMatches = [regex]::Matches($HeaderLine, '\S+(?:\s\S+)*')
                    $Columns = for ($i = 0; $i -lt $ColumnMatches.Count; $i++) {
                        [PSCustomObject]@{
                            Name  = $ColumnMatches[$i].Value.Trim()
                            Start = $ColumnMatches[$i].Index
                            End   = if ($i -lt $ColumnMatches.Count - 1) { $ColumnMatches[$i + 1].Index } else { -1 }
                        }
                    }
                    foreach ($Line in $DataLines) {
                        $Fields = @{}
                        foreach ($Column in $Columns) {
                            if ($Column.Start -lt $Line.Length) {
                                $Length = if ($Column.End -eq -1) { $Line.Length - $Column.Start } else { $Column.End - $Column.Start }
                                $EndIndex = [Math]::Min($Line.Length, $Column.Start + $Length)
                                $Fields[$Column.Name] = $Line.Substring($Column.Start, $EndIndex - $Column.Start).Trim()
                            }
                        }
                        [PSCustomObject]@{
                            Source    = 'Winget'
                            Name      = $Fields['Name']
                            Version   = $Fields['Version']
                            Publisher = $Fields['Source']
                        }
                    }
                }
            }
        }
    }
}
