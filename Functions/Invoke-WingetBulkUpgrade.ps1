#requires -Version 7.6

function Invoke-WingetBulkUpgrade {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$App
    )

    if (-not $PSCmdlet.ShouldProcess("$($App.Count) app(s)", 'Bulk upgrade via winget')) {
        foreach ($CurrentApp in $App) {
            [PSCustomObject]@{
                Name     = $CurrentApp.Name
                Id       = $CurrentApp.Id
                Result   = 'Skipped'
                ExitCode = $null
            }
        }
        return
    }

    foreach ($CurrentApp in $App) {
        # The batch was approved once above; -Confirm:$false stops Update-WingetApp's own
        # gate from asking again for every app.
        $Outcome = Update-WingetApp -Id $CurrentApp.Id -Detached:$CurrentApp.DetachedUpgrade -Confirm:$false

        # Emitted one per app as the loop runs, so a caller piping this can report
        # progress instead of waiting for the whole batch.
        [PSCustomObject]@{
            Name     = $CurrentApp.Name
            Id       = $CurrentApp.Id
            Result   = $Outcome.Result
            ExitCode = $Outcome.ExitCode
        }
    }
}
