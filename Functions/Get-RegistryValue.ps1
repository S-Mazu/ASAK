#requires -Version 7.6

function Get-RegistryValue {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    # Get-ItemPropertyValue is the obvious cmdlet for this and cannot be used: it writes a
    # non-terminating error when the value is missing and ignores -ErrorAction
    # SilentlyContinue, so enumerating keys that legitimately lack the value floods the
    # console. Reading the whole property bag and picking the value out yields $null
    # instead, and picking it via PSObject.Properties survives Set-StrictMode, which a bare
    # property access on a missing name would not.
    $Values = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
    if (-not $Values) {
        return $null
    }
    ($Values.PSObject.Properties[$Name])?.Value
}
