#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-IntuneEnrollment.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-ConfigMgrClient.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-DeviceManagement.ps1')
}

Describe 'Get-DeviceManagement' {
    Context 'Intune only' {
        BeforeAll {
            Mock Get-IntuneEnrollment { [PSCustomObject]@{ Enrolled = $true; Upn = 'user@example.com'; DiscoveryUrl = 'https://enrollment'; MdmCertNotAfter = $null } }
            Mock Get-ConfigMgrClient { [PSCustomObject]@{ Installed = $false; ClientVersion = $null; SiteCode = $null; ManagementPoint = $null; CoManagementFlags = $null } }
        }
        It 'reports ManagementMode Intune and carries the enrolled user through' {
            $Result = Get-DeviceManagement
            $Result.ManagementMode | Should -Be 'Intune'
            $Result.IntuneUpn | Should -Be 'user@example.com'
        }
    }

    Context 'ConfigMgr only' {
        BeforeAll {
            Mock Get-IntuneEnrollment { [PSCustomObject]@{ Enrolled = $false; Upn = $null; DiscoveryUrl = $null; MdmCertNotAfter = $null } }
            Mock Get-ConfigMgrClient { [PSCustomObject]@{ Installed = $true; ClientVersion = '5.00.9128.1006'; SiteCode = 'P01'; ManagementPoint = 'mp.example.com'; CoManagementFlags = $null } }
        }
        It 'reports ManagementMode ConfigMgr with the site code' {
            $Result = Get-DeviceManagement
            $Result.ManagementMode | Should -Be 'ConfigMgr'
            $Result.ConfigMgrSiteCode | Should -Be 'P01'
        }
    }

    Context 'both present' {
        BeforeAll {
            Mock Get-IntuneEnrollment { [PSCustomObject]@{ Enrolled = $true; Upn = 'user@example.com'; DiscoveryUrl = $null; MdmCertNotAfter = $null } }
            Mock Get-ConfigMgrClient { [PSCustomObject]@{ Installed = $true; ClientVersion = '5.00.9128.1006'; SiteCode = 'P01'; ManagementPoint = $null; CoManagementFlags = 1 } }
        }
        It 'reports ManagementMode CoManaged' {
            (Get-DeviceManagement).ManagementMode | Should -Be 'CoManaged'
        }
    }

    Context 'neither present' {
        BeforeAll {
            Mock Get-IntuneEnrollment { [PSCustomObject]@{ Enrolled = $false; Upn = $null; DiscoveryUrl = $null; MdmCertNotAfter = $null } }
            Mock Get-ConfigMgrClient { [PSCustomObject]@{ Installed = $false; ClientVersion = $null; SiteCode = $null; ManagementPoint = $null; CoManagementFlags = $null } }
        }
        It 'reports ManagementMode None' {
            (Get-DeviceManagement).ManagementMode | Should -Be 'None'
        }
    }
}
