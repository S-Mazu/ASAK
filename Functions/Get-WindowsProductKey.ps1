#requires -Version 7.6

function Get-WindowsProductKey {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # Windows' own ApplicationID. SoftwareLicensingProduct also lists Office and other
    # licensed products, each under a different ID.
    $WindowsApplicationId = '55c92734-d682-4d71-983e-d6ec3f16059f'

    $LicensingService = Get-CimInstance -ClassName SoftwareLicensingService
    $WindowsProduct = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID='$WindowsApplicationId' AND PartialProductKey IS NOT NULL" |
        Select-Object -First 1
    $ProductId = Get-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductId'

    $LicenseStatus = 'Unknown'
    if ($WindowsProduct) {
        $LicenseStatus = switch ($WindowsProduct.LicenseStatus) {
            0 { 'Unlicensed' }
            1 { 'Licensed' }
            2 { 'Out-of-box grace period' }
            3 { 'Out-of-tolerance grace period' }
            4 { 'Non-genuine grace period' }
            5 { 'Notification' }
            6 { 'Extended grace period' }
            default { 'Unknown' }
        }
    }

    # FirmwareProductKey is empty on retail installs and virtual machines - a valid result,
    # not a failure. The registry DigitalProductId blob is deliberately not decoded: on
    # current Windows it yields a generic placeholder key, which is worse than an empty field.
    [PSCustomObject]@{
        Edition            = ${WindowsProduct}?.Name
        LicenseStatus      = $LicenseStatus
        LicenseChannel     = ${WindowsProduct}?.ProductKeyChannel
        PartialProductKey  = ${WindowsProduct}?.PartialProductKey
        FirmwareProductKey = ${LicensingService}?.OA3xOriginalProductKey
        ProductId          = $ProductId
    }
}
