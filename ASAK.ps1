#requires -Version 7.6
#requires -RunAsAdministrator

$InformationPreference = 'Continue'
$AsakVersion = '0.2.0'

Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

$LastAppResult = $null
$LastFeatureResult = $null

function Show-AppsMenu {
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
            Name        = 'Package'
            Description = 'PowerShell/NuGet packages (e.g. modules from the PowerShell Gallery) - NOT desktop applications, a fundamentally different inventory than the other three sources.'
            Docs        = 'https://learn.microsoft.com/en-us/powershell/module/packagemanagement/get-package'
        }
        [PSCustomObject]@{
            Name        = 'Winget'
            Description = "Installed applications winget can identify, including ones installed by other means; also flags available updates. Parses winget list's fixed-width text output; breaks if the winget CLI's output format changes."
            Docs        = 'https://learn.microsoft.com/en-us/windows/package-manager/winget/list'
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
        return
    }

    $Script:LastAppResult = Get-InstalledApp -Source $Selected
    $Script:LastAppResult | Format-Table -AutoSize | Out-Host -Paging
}

function Show-FeaturesMenu {
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
        return
    }

    $Script:LastFeatureResult = Get-InstalledFeature -Source $SourceName
    $Script:LastFeatureResult | Format-Table -AutoSize | Out-Host -Paging
}

function Invoke-ExportPrompt {
    param(
        [PSObject[]]$Result,
        [Parameter(Mandatory)]
        [string]$DefaultFileName
    )

    if (-not $Result) {
        Write-Warning 'Nothing to export yet. Show it first.'
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
    Invoke-ExportPrompt -Result $Script:LastAppResult -DefaultFileName 'Get-InstalledApp.csv'
}

function Show-ExportFeaturesMenu {
    Invoke-ExportPrompt -Result $Script:LastFeatureResult -DefaultFileName 'Get-InstalledFeature.csv'
}

function Show-AppManagementMenu {
    do {
        Write-Information ''
        Write-Information '----- App Management -----'
        Write-Information '1) Show Installed Apps'
        Write-Information '2) Export Installed Apps to CSV'
        Write-Information '3) Show Installed Features'
        Write-Information '4) Export Installed Features to CSV'
        Write-Information '0) Back'
        $SubChoice = Read-Host 'Choice'

        switch ($SubChoice) {
            '1' { Show-AppsMenu }
            '2' { Show-ExportAppsMenu }
            '3' { Show-FeaturesMenu }
            '4' { Show-ExportFeaturesMenu }
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
    Write-Information '  App Management - inventory installed apps/features, view onscreen or export to CSV.'
    Write-Information '  Version Info   - this screen.'
    Write-Information ''
    Write-Information 'Release notes: see HISTORY.md.'
    Read-Host 'Press Enter to go back'
}

Clear-Host

do {
    Write-Information ''
    Write-Information "===== ASAK - Admin's Swiss Army Knife ====="
    Write-Information '1) App Management'
    Write-Information '2) Version Info'
    Write-Information '0) Exit'
    $MenuChoice = Read-Host 'Choice'

    switch ($MenuChoice) {
        '1' { Clear-Host; Show-AppManagementMenu; Clear-Host }
        '2' { Clear-Host; Show-VersionInfoMenu; Clear-Host }
        '0' { }
        default { Write-Warning 'Invalid choice.' }
    }
} while ($MenuChoice -ne '0')
