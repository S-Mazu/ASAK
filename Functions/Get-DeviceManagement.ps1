#requires -Version 7.6

function Get-DeviceManagement {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $Intune = Get-IntuneEnrollment
    $ConfigMgr = Get-ConfigMgrClient

    # Both at once is co-management, and telling that apart from either one alone is the
    # whole question. Domain and Entra join state deliberately stay out of this answer.
    $ManagementMode = if ($Intune.Enrolled -and $ConfigMgr.Installed) {
        'CoManaged'
    } elseif ($Intune.Enrolled) {
        'Intune'
    } elseif ($ConfigMgr.Installed) {
        'ConfigMgr'
    } else {
        'None'
    }

    [PSCustomObject]@{
        ManagementMode           = $ManagementMode
        IntuneEnrolled           = $Intune.Enrolled
        IntuneUpn                = $Intune.Upn
        IntuneDiscoveryUrl       = $Intune.DiscoveryUrl
        MdmCertNotAfter          = $Intune.MdmCertNotAfter
        ConfigMgrInstalled       = $ConfigMgr.Installed
        ConfigMgrVersion         = $ConfigMgr.ClientVersion
        ConfigMgrSiteCode        = $ConfigMgr.SiteCode
        ConfigMgrManagementPoint = $ConfigMgr.ManagementPoint
        CoManagementFlags        = $ConfigMgr.CoManagementFlags
    }
}
