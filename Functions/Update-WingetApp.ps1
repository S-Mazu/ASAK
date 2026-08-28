#requires -Version 7.6

function Update-WingetApp {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [switch]$Detached
    )

    # winget's exit code for "no applicable upgrade found" (0x8A15002B) - the app is
    # already current, distinct from an actual upgrade failure.
    $NoUpgradeAvailableExitCode = -1978335189

    if (-not $PSCmdlet.ShouldProcess($Id, 'Upgrade via winget')) {
        return [PSCustomObject]@{ Result = 'Skipped'; ExitCode = $null }
    }

    if ($Detached) {
        $Process = Start-Process -FilePath 'cmd.exe' -ArgumentList @(
            '/c', 'winget', 'upgrade', '--id', $Id, '--exact', '--silent',
            '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity'
        ) -Wait -PassThru
        $ExitCode = $Process.ExitCode
    } else {
        & winget upgrade --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null | Out-Null
        $ExitCode = $LASTEXITCODE
    }

    # The exit code travels with the status so a caller can report why an upgrade failed.
    if ($ExitCode -eq 0) {
        return [PSCustomObject]@{ Result = 'Upgraded'; ExitCode = $ExitCode }
    }
    if ($ExitCode -eq $NoUpgradeAvailableExitCode) {
        return [PSCustomObject]@{ Result = 'UpToDate'; ExitCode = $ExitCode }
    }
    return [PSCustomObject]@{ Result = 'Failed'; ExitCode = $ExitCode }
}
