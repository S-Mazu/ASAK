#requires -Version 7.6

function Get-PendingWindowsUpdate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # The Windows Update Agent COM API is the only local source that knows which updates this
    # machine is missing, and the only one that sees the patch level endoflife.date cannot
    # (ADR-013). The search installs nothing, but it refreshes the update metadata cache and
    # can run for minutes, so the caller is expected to bound it - see ADR-003.
    $Session = New-Object -ComObject 'Microsoft.Update.Session'
    $Searcher = $Session.CreateUpdateSearcher()
    $SearchResult = $Searcher.Search("IsInstalled=0 AND Type='Software' AND IsHidden=0")

    foreach ($Update in $SearchResult.Updates) {
        # One update can cover several KB articles, and driver-only entries cover none.
        $KnowledgeBase = @($Update.KBArticleIDs) | ForEach-Object { "KB$_" }

        [PSCustomObject]@{
            Title          = $Update.Title
            KB             = $KnowledgeBase -join ', '
            Severity       = $Update.MsrcSeverity
            IsMandatory    = $Update.IsMandatory
            RebootRequired = $Update.InstallationBehavior.RebootBehavior -ne 0
            SizeMb         = [math]::Round($Update.MaxDownloadSize / 1MB, 1)
        }
    }
}
