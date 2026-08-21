#requires -Version 7.6

function Update-WingetApp {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [switch]$Detached
    )

    if ($PSCmdlet.ShouldProcess($Id, 'Upgrade via winget')) {
        if ($Detached) {
            $Process = Start-Process -FilePath 'cmd.exe' -ArgumentList @(
                '/c', 'winget', 'upgrade', '--id', $Id, '--exact', '--silent',
                '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity'
            ) -Wait -PassThru
            return $Process.ExitCode -eq 0
        }
        & winget upgrade --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    return $false
}
