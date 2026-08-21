#requires -Version 7.6

function Install-WingetApp {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    if ($PSCmdlet.ShouldProcess($Id, 'Install via winget')) {
        & winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    return $false
}
