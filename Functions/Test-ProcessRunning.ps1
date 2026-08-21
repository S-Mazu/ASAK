#requires -Version 7.6

function Test-ProcessRunning {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return [bool](Get-Process -Name $Name -ErrorAction SilentlyContinue)
}
