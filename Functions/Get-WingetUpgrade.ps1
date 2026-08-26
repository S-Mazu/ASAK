#requires -Version 7.6

function Get-WingetUpgrade {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # Columns are resolved by position via ConvertFrom-WingetTable (ADR-010):
    # Name=0, Id=1, Version=2, Available=3. A trailing summary line (e.g.
    # "N upgrades available.") is excluded via the Id-column heuristic below.
    $Rows = @(ConvertFrom-WingetTable -Line (& winget upgrade --disable-interactivity 2>$null))

    foreach ($Values in $Rows) {
        if ($Values.Count -lt 4 -or $Values[1] -notmatch '^\S+\.\S+$') {
            continue
        }
        [PSCustomObject]@{
            Name      = $Values[0]
            Id        = $Values[1]
            Version   = $Values[2]
            Available = $Values[3]
        }
    }
}
