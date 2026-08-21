#requires -Version 7.6

function Test-WingetAppInstalled {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    & winget list --id $Id --exact --disable-interactivity 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
}
