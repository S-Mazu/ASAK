#requires -Version 7.6

function Get-WingetUpgrade {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # winget upgrade has no structured output mode; columns are fixed-width,
    # located from the header row's word-start offsets, same approach as
    # Get-InstalledApp's Winget branch. Unlike that branch, fields are read by
    # column POSITION (Name=0, Id=1, Version=2, Available=3), not by looking up
    # the header text - winget localizes "Available"/"Source" to the OS locale
    # (observed: German build prints "Verfuegbar"/"Quelle") while column order
    # stays stable. A trailing summary line (e.g. "N upgrades available.") is
    # excluded via the Id-column heuristic below.
    $Lines = @((& winget upgrade --disable-interactivity 2>$null) |
        Where-Object { $_.Trim() -ne '' })

    $HeaderIndex = 0
    while ($HeaderIndex -lt $Lines.Count -and $Lines[$HeaderIndex] -notmatch '^Name\s') {
        $HeaderIndex++
    }
    if ($HeaderIndex -ge $Lines.Count) {
        return
    }

    $HeaderLine = $Lines[$HeaderIndex]
    $FirstDataIndex = $HeaderIndex + 2
    if ($FirstDataIndex -gt $Lines.Count - 1) {
        return
    }
    $DataLines = $Lines[$FirstDataIndex..($Lines.Count - 1)]
    $ColumnStarts = [regex]::Matches($HeaderLine, '\S+(?:\s\S+)*') | ForEach-Object { $_.Index }

    foreach ($Line in $DataLines) {
        $Values = for ($i = 0; $i -lt $ColumnStarts.Count; $i++) {
            $Start = $ColumnStarts[$i]
            if ($Start -ge $Line.Length) {
                continue
            }
            $End = if ($i -lt $ColumnStarts.Count - 1) { [Math]::Min($Line.Length, $ColumnStarts[$i + 1]) } else { $Line.Length }
            $Line.Substring($Start, $End - $Start).Trim()
        }
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
