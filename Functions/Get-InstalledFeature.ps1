#requires -Version 7.6

function Get-InstalledFeature {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Optional', 'ServerManager')]
        [string]$Source
    )

    switch ($Source) {
        'Optional' {
            Get-WindowsOptionalFeature -Online |
                ForEach-Object {
                    [PSCustomObject]@{
                        Source = 'Optional'
                        Name   = $_.FeatureName
                        State  = $_.State
                    }
                }
        }
        'ServerManager' {
            Import-Module -Name ServerManager -ErrorAction Stop
            Get-WindowsFeature |
                ForEach-Object {
                    [PSCustomObject]@{
                        Source = 'ServerManager'
                        Name   = $_.Name
                        State  = $_.InstallState
                    }
                }
        }
    }
}
