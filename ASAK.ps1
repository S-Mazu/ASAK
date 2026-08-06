#requires -Version 7.6
#requires -RunAsAdministrator

$InformationPreference = 'Continue'

Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}

$LastResult = $null

function Show-AppsMenu {
    $Sources = @('Registry', 'Win32_Product', 'Package', 'Winget')
    Write-Information ''
    Write-Information 'Select app sources (comma-separated numbers):'
    for ($i = 0; $i -lt $Sources.Count; $i++) {
        Write-Information "  $($i + 1)) $($Sources[$i])"
    }
    $Choice = Read-Host 'Sources'
    $Selected = $Choice -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '^\d+$' } |
        ForEach-Object { [int]$_ } |
        Where-Object { $_ -ge 1 -and $_ -le $Sources.Count } |
        ForEach-Object { $Sources[$_ - 1] } |
        Select-Object -Unique

    if (-not $Selected) {
        Write-Warning 'No valid source selected.'
        return
    }

    $Script:LastResult = Get-InstalledApp -Source $Selected
    $Script:LastResult | Format-Table -AutoSize
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

    $Script:LastResult = Get-InstalledFeature -Source $SourceName
    $Script:LastResult | Format-Table -AutoSize
}

function Show-ExportMenu {
    if (-not $Script:LastResult) {
        Write-Warning 'Nothing to export yet. Run Show Installed Apps or Show Installed Features first.'
        return
    }

    $Path = Read-Host 'Export path (e.g. C:\Temp\inventory.csv)'
    if (-not $Path) {
        Write-Warning 'No path given, export cancelled.'
        return
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

    $Script:LastResult | Export-InventoryCsv -Path $Path -NoTypeInformation:$NoTypeInformation -Encoding $Encoding -Delimiter $Delimiter
    Write-Information "Exported to $Path"
}

do {
    Write-Information ''
    Write-Information "===== ASAK - Admin's Swiss Army Knife ====="
    Write-Information '1) Show Installed Apps'
    Write-Information '2) Show Installed Features'
    Write-Information '3) Export last result to CSV'
    Write-Information '0) Exit'
    $MenuChoice = Read-Host 'Choice'

    switch ($MenuChoice) {
        '1' { Show-AppsMenu }
        '2' { Show-FeaturesMenu }
        '3' { Show-ExportMenu }
        '0' { }
        default { Write-Warning 'Invalid choice.' }
    }
} while ($MenuChoice -ne '0')
