#requires -Version 7.6

function ConvertFrom-WingetTable {
    <#
    .SYNOPSIS
        Splits winget's fixed-width table output into positional field values.
    .DESCRIPTION
        winget has no structured output mode. Column boundaries are taken from
        the header row's word-start offsets; each data row is then cut at those
        offsets and returned by POSITION, never by header text - winget
        localizes header words to the OS locale while column order stays stable
        (ADR-010).

        Every emitted row has exactly one entry per header column. Columns the
        row is too short to reach come back as an empty string, so callers can
        index a trailing column (for example the last one) without a length
        check.
    .PARAMETER Line
        Raw output lines of a winget table command. Blank lines are ignored.
    .OUTPUTS
        System.String[] - one array of trimmed field values per data row.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        # Mandatory implies per-element ValidateNotNullOrEmpty; real winget
        # output contains blank lines, which would otherwise fail binding.
        [AllowEmptyString()]
        [string[]]$Line
    )

    $Lines = @($Line | Where-Object { $_ -and $_.Trim() -ne '' })

    # "Name" is the one header word winget leaves untranslated.
    $HeaderIndex = 0
    while ($HeaderIndex -lt $Lines.Count -and $Lines[$HeaderIndex] -notmatch '^Name\s') {
        $HeaderIndex++
    }
    if ($HeaderIndex -ge $Lines.Count) {
        return
    }

    # Header row is followed by a "-----" rule line before the first data row.
    $FirstDataIndex = $HeaderIndex + 2
    if ($FirstDataIndex -gt $Lines.Count - 1) {
        return
    }

    # A single space inside a match keeps two-word headers together; two or more
    # spaces separate columns.
    $ColumnStarts = @([regex]::Matches($Lines[$HeaderIndex], '\S+(?:\s\S+)*') | ForEach-Object { $_.Index })

    foreach ($DataLine in $Lines[$FirstDataIndex..($Lines.Count - 1)]) {
        $Values = for ($i = 0; $i -lt $ColumnStarts.Count; $i++) {
            $Start = $ColumnStarts[$i]
            if ($Start -ge $DataLine.Length) {
                ''
                continue
            }
            $End = if ($i -lt $ColumnStarts.Count - 1) { [Math]::Min($DataLine.Length, $ColumnStarts[$i + 1]) } else { $DataLine.Length }
            $DataLine.Substring($Start, $End - $Start).Trim()
        }
        # -NoEnumerate keeps the row together as one pipeline item; callers wrap
        # the call in @() so a single row does not unroll into its own fields.
        Write-Output -NoEnumerate -InputObject ([string[]]$Values)
    }
}
