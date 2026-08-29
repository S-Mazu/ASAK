#requires -Version 7.6

function Get-ConfigMgrClient {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # The root\ccm namespace exists only where the ConfigMgr client is actually installed,
    # which makes it the authoritative signal. The Enrollments registry is not a substitute:
    # a WMI_Bridge_SCCM_Server provider entry sits on machines with no client at all
    # (ADR-014).
    $Client = Get-CimInstance -Namespace 'root\ccm' -ClassName 'SMS_Client' -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $Client) {
        return [PSCustomObject]@{
            Installed         = $false
            ClientVersion     = $null
            SiteCode          = $null
            ManagementPoint   = $null
            CoManagementFlags = $null
        }
    }

    $Authority = Get-CimInstance -Namespace 'root\ccm' -ClassName 'SMS_Authority' -ErrorAction SilentlyContinue |
        Select-Object -First 1

    # Written only once co-management is actually configured, so absent on a plain client.
    $CoManagementFlags = Get-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\CCM\CoManagementFlags' -Name 'ComanagementFlags'

    [PSCustomObject]@{
        Installed         = $true
        ClientVersion     = $Client.ClientVersion
        # SMS_Authority names itself "SMS:<SiteCode>"; only the site code is useful here.
        SiteCode          = ${Authority}?.Name -replace '^SMS:', ''
        ManagementPoint   = ${Authority}?.CurrentManagementPoint
        CoManagementFlags = $CoManagementFlags
    }
}
