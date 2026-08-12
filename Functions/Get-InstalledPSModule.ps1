#requires -Version 7.6

function Get-InstalledPSModule {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Module', 'Package')]
        [string[]]$Source
    )

    foreach ($CurrentSource in $Source) {
        switch ($CurrentSource) {
            'Module' {
                $ModuleRoots = ($env:PSModulePath -split [System.IO.Path]::PathSeparator) |
                    Where-Object { $_ } |
                    ForEach-Object { $_.TrimEnd('\', '/') }

                Get-Module -ListAvailable |
                    ForEach-Object {
                        $ModuleBase = $_.ModuleBase
                        $MatchedRoot = $ModuleRoots |
                            Where-Object { $ModuleBase.StartsWith("$_\", [System.StringComparison]::OrdinalIgnoreCase) } |
                            Select-Object -First 1
                        [PSCustomObject]@{
                            Name      = $_.Name
                            Version   = $_.Version
                            Publisher = $_.Author
                            Source    = if ($MatchedRoot) { $MatchedRoot } else { $ModuleBase }
                        }
                    }
            }
            'Package' {
                Get-Package -Name '*' |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Name      = $_.Name
                            Version   = $_.Version
                            Publisher = $_.ProviderName
                            Source    = 'Package'
                        }
                    }
            }
        }
    }
}
