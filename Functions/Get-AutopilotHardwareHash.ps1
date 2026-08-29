#requires -Version 7.6

function Get-AutopilotHardwareHash {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    try {
        # DeviceHardwareData is exposed only through the MDM device-detail bridge, and only
        # to an elevated caller - unelevated it fails with access denied.
        $DeviceDetail = Get-CimInstance -Namespace 'root/cimv2/mdm/dmmap' -ClassName 'MDM_DevDetail_Ext01' -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" -ErrorAction Stop
    } catch {
        throw "Could not read the Autopilot hardware hash - $($_.Exception.Message) Reading it requires an elevated session."
    }

    # The property names carry spaces because they are the literal column headers Intune's
    # Autopilot device import expects. Nothing else may join them: an extra column makes the
    # exported CSV unimportable.
    [PSCustomObject]@{
        'Device Serial Number' = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
        'Windows Product ID'   = (Get-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductId')
        'Hardware Hash'        = ${DeviceDetail}?.DeviceHardwareData
    }
}
