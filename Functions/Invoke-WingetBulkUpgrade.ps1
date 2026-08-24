#requires -Version 7.6

function Invoke-WingetBulkUpgrade {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$App
    )

    if ($PSCmdlet.ShouldProcess("$($App.Count) app(s)", 'Bulk upgrade via winget')) {
        foreach ($CurrentApp in $App) {
            [PSCustomObject]@{
                Name   = $CurrentApp.Name
                Id     = $CurrentApp.Id
                Result = Update-WingetApp -Id $CurrentApp.Id -Detached:$CurrentApp.DetachedUpgrade
            }
        }
    } else {
        foreach ($CurrentApp in $App) {
            [PSCustomObject]@{
                Name   = $CurrentApp.Name
                Id     = $CurrentApp.Id
                Result = 'Skipped'
            }
        }
    }
}
