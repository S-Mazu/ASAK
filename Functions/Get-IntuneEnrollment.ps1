#requires -Version 7.6

function Get-IntuneEnrollment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $EnrollmentsPath = 'HKLM:\SOFTWARE\Microsoft\Enrollments'

    # 'MS DM Server' is the provider Intune registers. The other keys under Enrollments -
    # Local Authority, Cloud Authority, Deploy Authority, WMI_Bridge_SCCM_Server - exist on
    # unmanaged machines too, so the provider name is what identifies an Intune enrollment.
    # Most keys under here carry none of these values at all, hence Get-RegistryValue.
    $Enrollment = Get-ChildItem -Path $EnrollmentsPath -ErrorAction SilentlyContinue |
        ForEach-Object {
            [PSCustomObject]@{
                Id           = $_.PSChildName
                ProviderId   = Get-RegistryValue -Path $_.PSPath -Name 'ProviderID'
                State        = Get-RegistryValue -Path $_.PSPath -Name 'EnrollmentState'
                Upn          = Get-RegistryValue -Path $_.PSPath -Name 'UPN'
                Type         = Get-RegistryValue -Path $_.PSPath -Name 'EnrollmentType'
                DiscoveryUrl = Get-RegistryValue -Path $_.PSPath -Name 'DiscoveryServiceFullURL'
            }
        } |
        Where-Object { $_.ProviderId -eq 'MS DM Server' -and $_.State -eq 1 } |
        Select-Object -First 1

    # The MDM device certificate is what authenticates the machine to Intune, so its expiry
    # belongs next to the enrollment. Reading it needs elevation; absence is not a failure.
    $MdmCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
        Where-Object { $_.Issuer -match 'Microsoft Intune MDM Device CA' } |
        Sort-Object -Property NotAfter -Descending |
        Select-Object -First 1

    [PSCustomObject]@{
        Enrolled          = [bool]$Enrollment
        EnrollmentId      = ${Enrollment}?.Id
        Upn               = ${Enrollment}?.Upn
        EnrollmentType    = ${Enrollment}?.Type
        DiscoveryUrl      = ${Enrollment}?.DiscoveryUrl
        MdmCertThumbprint = ${MdmCertificate}?.Thumbprint
        MdmCertNotAfter   = ${MdmCertificate}?.NotAfter
    }
}
