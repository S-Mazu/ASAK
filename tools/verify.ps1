#requires -Version 7.6
#requires -Modules PSScriptAnalyzer, Pester

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$SettingsPath = Join-Path $RepoRoot 'PSScriptAnalyzerSettings.psd1'
$TestsPath = Join-Path $RepoRoot 'Tests'

$BaseSettings = Import-PowerShellDataFile -Path $SettingsPath
# Pester test doubles legitimately shadow built-in cmdlet names (e.g. stubbing Get-Package
# so Mock can build a proxy for it) - exempt Tests\ from this one rule, not the whole repo.
$TestsSettings = @{
    Severity     = $BaseSettings.Severity
    ExcludeRules = @($BaseSettings.ExcludeRules) + 'PSAvoidOverwritingBuiltInCmdlets'
}

$ProductionPaths = Get-ChildItem -Path $RepoRoot -Force -Exclude 'Tests', '.git'
$AnalyzerResults = @(
    foreach ($ProductionPath in $ProductionPaths.FullName) {
        Invoke-ScriptAnalyzer -Path $ProductionPath -Recurse -Settings $SettingsPath
    }
    Invoke-ScriptAnalyzer -Path $TestsPath -Recurse -Settings $TestsSettings
)
if ($AnalyzerResults) {
    $AnalyzerResults | Format-Table -AutoSize
    throw "PSScriptAnalyzer found $($AnalyzerResults.Count) issue(s)."
}

$PesterConfig = New-PesterConfiguration
$PesterConfig.Run.Path = Join-Path $RepoRoot 'Tests'
$PesterConfig.Run.Throw = $true
$PesterConfig.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $PesterConfig
