#requires -Version 7.6

function Uninstall-WingetApp {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    if ($PSCmdlet.ShouldProcess($Id, 'Uninstall via winget')) {
        & winget uninstall --id $Id --exact --silent --disable-interactivity 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    return $false
}
