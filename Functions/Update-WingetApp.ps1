#requires -Version 7.6

function Update-WingetApp {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    if ($PSCmdlet.ShouldProcess($Id, 'Upgrade via winget')) {
        & winget upgrade --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    return $false
}
