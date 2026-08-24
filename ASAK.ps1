#requires -Version 7.6
#requires -RunAsAdministrator

$InformationPreference = 'Continue'
$AsakVersion = '0.3.0'
$FeatureQueryTimeoutSeconds = 30

Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

$LastAppResult = $null
$LastFeatureResult = $null
$LastModuleResult = $null

$Script:WingetCuratedApps = @(
    [PSCustomObject]@{ Name = 'Docker Desktop'; Id = 'Docker.DockerDesktop'; ProcessName = 'Docker Desktop'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Claude Code'; Id = 'Anthropic.ClaudeCode'; ProcessName = $null; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'VLC Player'; Id = 'VideoLAN.VLC'; ProcessName = 'vlc'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Chrome Browser'; Id = 'Google.Chrome'; ProcessName = 'chrome'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Gimp'; Id = 'GIMP.GIMP'; ProcessName = 'gimp*'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Teams for Business'; Id = 'Microsoft.Teams'; ProcessName = 'ms-teams'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'OneDrive for Business'; Id = 'Microsoft.OneDrive'; ProcessName = 'OneDrive'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Git for Windows'; Id = 'Git.Git'; ProcessName = $null; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Claude Desktop App'; Id = 'Anthropic.Claude'; ProcessName = 'Claude'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Spotify'; Id = 'Spotify.Spotify'; ProcessName = 'Spotify'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'Irfanview'; Id = 'IrfanSkiljan.IrfanView'; ProcessName = 'i_view*'; UpgradeOnly = $false; DetachedUpgrade = $false }
    [PSCustomObject]@{ Name = 'PowerShell 7 (upgrade only)'; Id = 'Microsoft.PowerShell'; ProcessName = $null; UpgradeOnly = $true; DetachedUpgrade = $true }
    [PSCustomObject]@{ Name = 'Notepad++'; Id = 'Notepad++.Notepad++'; ProcessName = 'notepad++'; UpgradeOnly = $false; DetachedUpgrade = $false }
)

function Select-AppSource {
    $Sources = @(
        [PSCustomObject]@{
            Name        = 'Registry'
            Description = 'Installed Win32 desktop apps, as listed in Add/Remove Programs. Fast, no side effects; relies on vendors populating the uninstall keys correctly.'
            Docs        = 'https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-itemproperty'
        }
        [PSCustomObject]@{
            Name        = 'Win32_Product'
            Description = 'Installed MSI-based apps only. Triggers an MSI consistency-check/repair on every enumeration.'
            Docs        = 'https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance'
        }
        [PSCustomObject]@{
            Name        = 'Winget'
            Description = "Installed applications winget can identify, including ones installed by other means; also flags available updates. Parses winget list's fixed-width text output; breaks if the winget CLI's output format changes."
            Docs        = 'https://learn.microsoft.com/en-us/windows/package-manager/winget/list'
        }
        [PSCustomObject]@{
            Name        = 'Appx'
            Description = 'Installed AppX/UWP packages (Store apps and system UWP components), current-user scope.'
            Docs        = 'https://learn.microsoft.com/en-us/powershell/module/appx/get-appxpackage'
        }
    )
    Write-Information ''
    Write-Information 'Select app sources (comma-separated numbers):'
    for ($i = 0; $i -lt $Sources.Count; $i++) {
        Write-Information "  $($i + 1)) $($Sources[$i].Name)"
        Write-Information "      $($Sources[$i].Description)"
        Write-Information "      docs: $($Sources[$i].Docs)"
    }
    $Choice = Read-Host 'Sources'
    $Selected = $Choice -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d+$' } |
        ForEach-Object { [int]$_ } |
        Where-Object { $_ -ge 1 -and $_ -le $Sources.Count } |
        ForEach-Object { $Sources[$_ - 1].Name } |
        Select-Object -Unique

    if (-not $Selected) {
        Write-Warning 'No valid source selected.'
        return $null
    }

    return $Selected
}

function Select-FeatureSource {
    Write-Information ''
    Write-Information 'Select a feature source:'
    Write-Information '  1) Optional      - Get-WindowsOptionalFeature (DISM-based, works on client and Server)'
    Write-Information '  2) ServerManager - Get-WindowsFeature (Server only, fails on client SKUs)'
    $Choice = Read-Host 'Source'

    $SourceName = switch ($Choice) {
        '1' { 'Optional' }
        '2' { 'ServerManager' }
        default { $null }
    }

    if (-not $SourceName) {
        Write-Warning 'No valid source selected.'
        return $null
    }

    return $SourceName
}

function Select-ModuleSource {
    $Sources = @(
        [PSCustomObject]@{
            Name        = 'Module'
            Description = 'PowerShell modules present on PSModulePath (any install method), tagged with the literal PSModulePath segment they were found under.'
            Docs        = 'https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-module'
        }
        [PSCustomObject]@{
            Name        = 'Package'
            Description = 'PowerShell/NuGet packages installed via PackageManagement (Install-Module/Install-Script) - in practice PowerShell-only under PS7, since the msi/Programs providers do not load under pwsh.'
            Docs        = 'https://learn.microsoft.com/en-us/powershell/module/packagemanagement/get-package'
        }
    )
    Write-Information ''
    Write-Information 'Select module sources (comma-separated numbers):'
    for ($i = 0; $i -lt $Sources.Count; $i++) {
        Write-Information "  $($i + 1)) $($Sources[$i].Name)"
        Write-Information "      $($Sources[$i].Description)"
        Write-Information "      docs: $($Sources[$i].Docs)"
    }
    $Choice = Read-Host 'Sources'
    $Selected = $Choice -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d+$' } |
        ForEach-Object { [int]$_ } |
        Where-Object { $_ -ge 1 -and $_ -le $Sources.Count } |
        ForEach-Object { $Sources[$_ - 1].Name } |
        Select-Object -Unique

    if (-not $Selected) {
        Write-Warning 'No valid source selected.'
        return $null
    }

    return $Selected
}

function Get-AppInventory {
    $Selected = Select-AppSource
    if (-not $Selected) {
        return $null
    }
    Get-InstalledApp -Source $Selected
}

function Get-FeatureInventory {
    $SourceName = Select-FeatureSource
    if (-not $SourceName) {
        return $null
    }

    $FunctionPath = Join-Path $PSScriptRoot 'Functions' 'Get-InstalledFeature.ps1'
    $Job = Start-Job -ScriptBlock {
        . $using:FunctionPath
        Get-InstalledFeature -Source $using:SourceName
    }

    $Remediation = 'Try from an elevated prompt: sfc /scannow  and  DISM /Online /Cleanup-Image /RestoreHealth'

    if (-not (Wait-Job -Job $Job -Timeout $Script:FeatureQueryTimeoutSeconds)) {
        Stop-Job -Job $Job
        Remove-Job -Job $Job -Force
        Write-Warning "Could not list $SourceName features - the query did not finish within $Script:FeatureQueryTimeoutSeconds seconds and was aborted.`n$Remediation"
        return $null
    }

    try {
        Receive-Job -Job $Job -ErrorAction Stop
    } catch {
        Write-Warning "Could not list $SourceName features - the underlying Windows component did not respond.`n$Remediation"
        return $null
    } finally {
        Remove-Job -Job $Job -Force
    }
}

function Get-ModuleInventory {
    $Selected = Select-ModuleSource
    if (-not $Selected) {
        return $null
    }
    Get-InstalledPSModule -Source $Selected
}

function Show-AppsMenu {
    $Result = Get-AppInventory
    if (-not $Result) {
        return
    }
    $Script:LastAppResult = $Result
    try {
        $Script:LastAppResult | Format-Table -AutoSize -Wrap | Out-Host -Paging
    } catch {
        if ($_.CategoryInfo.Category -ne 'OperationStopped') {
            throw
        }
    }
}

function Show-FeaturesMenu {
    $Result = Get-FeatureInventory
    if (-not $Result) {
        return
    }
    $Script:LastFeatureResult = $Result
    try {
        $Script:LastFeatureResult | Format-Table -AutoSize -Wrap | Out-Host -Paging
    } catch {
        if ($_.CategoryInfo.Category -ne 'OperationStopped') {
            throw
        }
    }
}

function Show-ModulesMenu {
    $Result = Get-ModuleInventory
    if (-not $Result) {
        return
    }
    $Script:LastModuleResult = $Result
    try {
        $Script:LastModuleResult | Format-Table -AutoSize -Wrap | Out-Host -Paging
    } catch {
        if ($_.CategoryInfo.Category -ne 'OperationStopped') {
            throw
        }
    }
}

function Invoke-ExportPrompt {
    param(
        [PSObject[]]$Result,
        [Parameter(Mandatory)]
        [string]$DefaultFileName
    )

    if (-not $Result) {
        Write-Warning 'Nothing to export - no results were found.'
        return
    }

    $Path = Read-Host "Export path (default .\$DefaultFileName)"
    if (-not $Path) {
        $Path = ".\$DefaultFileName"
    }

    $NoTypeChoice = Read-Host 'Include type information line? (y/N)'
    $NoTypeInformation = $NoTypeChoice -notmatch '^[Yy]'

    Write-Information 'Encoding: 1) UTF8  2) ASCII  3) Unicode  4) UTF7  5) UTF32  6) Default'
    $EncodingChoice = Read-Host 'Encoding (default UTF8)'
    $Encoding = switch ($EncodingChoice) {
        '2' { 'ASCII' }
        '3' { 'Unicode' }
        '4' { 'UTF7' }
        '5' { 'UTF32' }
        '6' { 'Default' }
        default { 'UTF8' }
    }

    $Delimiter = Read-Host 'Delimiter (default ;)'
    if (-not $Delimiter) {
        $Delimiter = ';'
    }

    $Result | Export-InventoryCsv -Path $Path -NoTypeInformation:$NoTypeInformation -Encoding $Encoding -Delimiter $Delimiter
    Write-Information "Exported to $Path"
}

function Show-ExportAppsMenu {
    $Result = Get-AppInventory
    if (-not $Result) {
        return
    }
    Invoke-ExportPrompt -Result $Result -DefaultFileName 'Get-InstalledApp.csv'
}

function Show-ExportFeaturesMenu {
    $Result = Get-FeatureInventory
    if (-not $Result) {
        return
    }
    Invoke-ExportPrompt -Result $Result -DefaultFileName 'Get-InstalledFeature.csv'
}

function Show-ExportModulesMenu {
    $Result = Get-ModuleInventory
    if (-not $Result) {
        return
    }
    Invoke-ExportPrompt -Result $Result -DefaultFileName 'Get-InstalledPSModule.csv'
}

function Show-ModuleManagementMenu {
    do {
        Write-Information ''
        Write-Information '----- PowerShell Modules -----'
        Write-Information '1) Show Installed Modules'
        Write-Information '2) Export Installed Modules to CSV'
        Write-Information '0) Back'
        $SubChoice = Read-Host 'Choice'

        switch ($SubChoice) {
            '1' { Show-ModulesMenu }
            '2' { Show-ExportModulesMenu }
            '0' { }
            default { Write-Warning 'Invalid choice.' }
        }
    } while ($SubChoice -ne '0')
}

function Show-AppManagementMenu {
    do {
        Write-Information ''
        Write-Information '----- Installed Apps -----'
        Write-Information '1) Show Installed Apps'
        Write-Information '2) Export Installed Apps to CSV'
        Write-Information '0) Back'
        $SubChoice = Read-Host 'Choice'

        switch ($SubChoice) {
            '1' { Show-AppsMenu }
            '2' { Show-ExportAppsMenu }
            '0' { }
            default { Write-Warning 'Invalid choice.' }
        }
    } while ($SubChoice -ne '0')
}

function Show-FeatureManagementMenu {
    do {
        Write-Information ''
        Write-Information '----- Windows Features -----'
        Write-Information '1) Show Installed Features'
        Write-Information '2) Export Installed Features to CSV'
        Write-Information '0) Back'
        $SubChoice = Read-Host 'Choice'

        switch ($SubChoice) {
            '1' { Show-FeaturesMenu }
            '2' { Show-ExportFeaturesMenu }
            '0' { }
            default { Write-Warning 'Invalid choice.' }
        }
    } while ($SubChoice -ne '0')
}

function Invoke-WingetAppAction {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$App
    )

    if ($App.UpgradeOnly -or (Test-WingetAppInstalled -Id $App.Id)) {
        if ($App.UpgradeOnly) {
            Write-Information "$($App.Name) is managed as upgrade-only."
            Write-Information '  U) Upgrade   C) Cancel'
        } else {
            Write-Information "$($App.Name) is already installed."
            Write-Information '  U) Upgrade   X) Uninstall   C) Cancel'
        }
        $Action = Read-Host 'Choice'
        switch ($Action) {
            'U' {
                switch (Update-WingetApp -Id $App.Id -Detached:$App.DetachedUpgrade) {
                    'Upgraded' { Write-Information "$($App.Name) upgraded." }
                    'UpToDate' { Write-Information "$($App.Name) is already up to date." }
                    'Skipped' { Write-Information 'Cancelled.' }
                    default { Write-Warning "Upgrade failed for $($App.Name)." }
                }
            }
            'X' {
                if ($App.UpgradeOnly) {
                    Write-Warning 'Uninstall is not available for this app.'
                } else {
                    $ProceedWithUninstall = $true
                    if ($App.ProcessName -and (Test-ProcessRunning -Name $App.ProcessName)) {
                        $RunningConfirm = Read-Host "$($App.Name) appears to be running. Uninstall anyway? (y/N)"
                        $ProceedWithUninstall = $RunningConfirm -match '^[Yy]'
                    }
                    if ($ProceedWithUninstall) {
                        if (Uninstall-WingetApp -Id $App.Id) {
                            Write-Information "$($App.Name) uninstalled."
                        } else {
                            Write-Warning "Uninstall failed for $($App.Name)."
                        }
                    } else {
                        Write-Information 'Cancelled.'
                    }
                }
            }
            default { Write-Information 'Cancelled.' }
        }
    } else {
        $Confirm = Read-Host "$($App.Name) is not installed. Install via winget? (y/N)"
        if ($Confirm -match '^[Yy]') {
            if (Install-WingetApp -Id $App.Id) {
                Write-Information "$($App.Name) installed."
            } else {
                Write-Warning "Install failed for $($App.Name)."
            }
        } else {
            Write-Information 'Cancelled.'
        }
    }
}

function Select-WingetUpgradeScope {
    Write-Information ''
    Write-Information 'Select which apps to upgrade:'
    Write-Information '  1) Curated - only pending upgrades for apps in this menu'
    Write-Information '  2) All     - every winget-detected upgrade on this machine'
    $Choice = Read-Host 'Scope'

    $ScopeName = switch ($Choice) {
        '1' { 'Curated' }
        '2' { 'All' }
        default { $null }
    }

    if (-not $ScopeName) {
        Write-Warning 'No valid scope selected.'
        return $null
    }

    return $ScopeName
}

function Show-WingetBulkUpgradeMenu {
    $ScopeName = Select-WingetUpgradeScope
    if (-not $ScopeName) {
        return
    }

    $Pending = Get-WingetUpgrade
    if ($ScopeName -eq 'Curated') {
        $CuratedIds = $Script:WingetCuratedApps.Id
        $Pending = $Pending | Where-Object { $_.Id -in $CuratedIds }
    }

    if (-not $Pending) {
        Write-Information 'No pending upgrades found.'
        return
    }

    $Apps = foreach ($PendingApp in $Pending) {
        $CuratedMatch = $Script:WingetCuratedApps | Where-Object { $_.Id -eq $PendingApp.Id } | Select-Object -First 1
        [PSCustomObject]@{
            Name            = $PendingApp.Name
            Id              = $PendingApp.Id
            DetachedUpgrade = if ($CuratedMatch) { $CuratedMatch.DetachedUpgrade } else { $false }
        }
    }

    $Result = Invoke-WingetBulkUpgrade -App $Apps
    try {
        $Result | Format-Table -AutoSize -Wrap | Out-Host -Paging
    } catch {
        if ($_.CategoryInfo.Category -ne 'OperationStopped') {
            throw
        }
    }
}

function Show-WingetMenu {
    do {
        Write-Information ''
        Write-Information '----- Winget - Common Apps -----'
        for ($i = 0; $i -lt $Script:WingetCuratedApps.Count; $i++) {
            Write-Information "$($i + 1)) $($Script:WingetCuratedApps[$i].Name)"
        }
        Write-Information 'B) Bulk-upgrade pending updates'
        Write-Information '0) Back'
        $AppChoice = Read-Host 'Choice'

        $Index = 0
        if ($AppChoice -eq '0') {
            continue
        } elseif ($AppChoice -match '^[Bb]$') {
            Show-WingetBulkUpgradeMenu
        } elseif ([int]::TryParse($AppChoice, [ref]$Index) -and $Index -ge 1 -and $Index -le $Script:WingetCuratedApps.Count) {
            Invoke-WingetAppAction -App $Script:WingetCuratedApps[$Index - 1]
        } else {
            Write-Warning 'Invalid choice.'
        }
    } while ($AppChoice -ne '0')
}

function Show-SoftwareInstallMenu {
    do {
        Write-Information ''
        Write-Information '----- Software Install -----'
        Write-Information '1) Winget'
        Write-Information '0) Back'
        $SubChoice = Read-Host 'Choice'

        switch ($SubChoice) {
            '1' { Show-WingetMenu }
            '0' { }
            default { Write-Warning 'Invalid choice.' }
        }
    } while ($SubChoice -ne '0')
}

function Show-VersionInfoMenu {
    Write-Information ''
    Write-Information "ASAK version $AsakVersion"
    Write-Information ''
    Write-Information 'Usage:'
    Write-Information '  PowerShell Modules - inventory installed PowerShell modules, view onscreen or export to CSV.'
    Write-Information '  Installed Apps     - inventory installed apps, view onscreen or export to CSV.'
    Write-Information '  Windows Features   - inventory installed Windows features, view onscreen or export to CSV.'
    Write-Information '  Software Install   - check/install/upgrade/uninstall common apps via winget; bulk-upgrade pending updates.'
    Write-Information '  Version Info       - this screen.'
    Write-Information ''
    Write-Information 'Release notes: see HISTORY.md.'
    Read-Host 'Press Enter to go back'
}

Clear-Host

do {
    Write-Information ''
    Write-Information "===== ASAK - Admin's Swiss Army Knife ====="
    Write-Information '1) PowerShell Modules'
    Write-Information '2) Installed Apps'
    Write-Information '3) Windows Features'
    Write-Information '4) Software Install'
    Write-Information '5) Version Info'
    Write-Information '0) Exit'
    $MenuChoice = Read-Host 'Choice'

    switch ($MenuChoice) {
        '1' { Clear-Host; Show-ModuleManagementMenu; Clear-Host }
        '2' { Clear-Host; Show-AppManagementMenu; Clear-Host }
        '3' { Clear-Host; Show-FeatureManagementMenu; Clear-Host }
        '4' { Clear-Host; Show-SoftwareInstallMenu; Clear-Host }
        '5' { Clear-Host; Show-VersionInfoMenu; Clear-Host }
        '0' { }
        default { Write-Warning 'Invalid choice.' }
    }
} while ($MenuChoice -ne '0')
