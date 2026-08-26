#requires -Version 7.6

function Get-InstalledApp {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Registry', 'Win32_Product', 'Winget', 'Appx')]
        [string[]]$Source
    )

    foreach ($CurrentSource in $Source) {
        switch ($CurrentSource) {
            'Registry' {
                $UninstallPaths = @(
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                )
                Get-ItemProperty -Path $UninstallPaths -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName } |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Source    = 'Registry'
                            Name      = $_.DisplayName
                            Version   = $_.DisplayVersion
                            Publisher = $_.Publisher
                        }
                    }
            }
            'Win32_Product' {
                Get-CimInstance -ClassName Win32_Product |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Source    = 'Win32_Product'
                            Name      = $_.Name
                            Version   = $_.Version
                            Publisher = $_.Vendor
                        }
                    }
            }
            'Winget' {
                # Fields are read by column position via ConvertFrom-WingetTable
                # (ADR-010). winget list carries no publisher information at
                # all, so Publisher stays empty for this source - its Source
                # column names the package source (winget/msstore), not a
                # publisher.
                $Rows = @(ConvertFrom-WingetTable -Line (& winget list --disable-interactivity 2>$null))
                foreach ($Values in $Rows) {
                    [PSCustomObject]@{
                        Source    = 'Winget'
                        Name      = $Values[0]
                        Version   = $Values[2]
                        Publisher = $null
                    }
                }
            }
            'Appx' {
                Get-AppxPackage |
                    ForEach-Object {
                        [PSCustomObject]@{
                            Source    = 'Appx'
                            Name      = $_.Name
                            Version   = $_.Version
                            Publisher = $_.Publisher
                        }
                    }
            }
        }
    }
}
