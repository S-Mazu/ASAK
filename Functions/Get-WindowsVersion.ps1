#requires -Version 7.6

function Get-WindowsVersion {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [int]$TimeoutSeconds = 15
    )

    $CurrentVersionPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

    # Caption is the product name. The registry's ProductName is deliberately not read: it
    # still reports "Windows 10 Pro" on Windows 11, confirmed on the test machine.
    $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    $DisplayVersion = Get-RegistryValue -Path $CurrentVersionPath -Name 'DisplayVersion'
    $CurrentBuild = Get-RegistryValue -Path $CurrentVersionPath -Name 'CurrentBuild'
    $Ubr = Get-RegistryValue -Path $CurrentVersionPath -Name 'UBR'
    $EditionId = Get-RegistryValue -Path $CurrentVersionPath -Name 'EditionID'
    $InstallationType = Get-RegistryValue -Path $CurrentVersionPath -Name 'InstallationType'

    $Cycle = $null
    $NewestOnTrack = $null
    $IsOutOfSupport = $null
    $CheckError = $null

    # endoflife.date is the only free source publishing latest build and support dates as
    # JSON; Microsoft's release-health equivalent is HTML only (ADR-013). A lookup that
    # fails is recorded, not thrown - ASAK has to stay usable offline.
    $Product = if ($InstallationType -eq 'Server') { 'windows-server' } else { 'windows' }
    try {
        $Cycles = Invoke-RestMethod -Uri "https://endoflife.date/api/$Product.json" -TimeoutSec $TimeoutSeconds -ErrorAction Stop

        # Enterprise and Education releases get a longer support window than the consumer
        # ones and are published as separate cycles - "11-25h2-e" against "11-25h2-w".
        $Track = if ($EditionId -in 'Enterprise', 'EnterpriseS', 'Education', 'IoTEnterprise') { 'e' } else { 'w' }
        $TrackPattern = '-' + $Track + '(-|$)'

        $Matching = @($Cycles | Where-Object { $_.latest -eq "10.0.$CurrentBuild" })
        $Cycle = $Matching | Where-Object { $_.cycle -match $TrackPattern } | Select-Object -First 1
        if (-not $Cycle) {
            $Cycle = $Matching | Select-Object -First 1
        }

        if ($Cycle) {
            # Newest release on the same track and the same Windows major version - comparing
            # a Windows 10 machine against a Windows 11 release would be a different question.
            $Major = ($Cycle.cycle -split '-')[0]
            $NewestOnTrack = $Cycles |
                Where-Object { $_.cycle -like "$Major-*" -and $_.cycle -match $TrackPattern } |
                Sort-Object -Property { [datetime]$_.releaseDate } -Descending |
                Select-Object -First 1

            # eol is a date on a dated release and a bare boolean on one with no date set.
            $EndOfLifeDate = $Cycle.eol -as [datetime]
            if ($EndOfLifeDate) {
                $IsOutOfSupport = $EndOfLifeDate -lt (Get-Date)
            }
        } else {
            $CheckError = "No published release matches build $CurrentBuild."
        }
    } catch {
        $CheckError = $_.Exception.Message
    }

    [PSCustomObject]@{
        Caption                = $OperatingSystem.Caption
        DisplayVersion         = $DisplayVersion
        Build                  = $CurrentBuild
        Ubr                    = $Ubr
        Edition                = $EditionId
        Architecture           = $OperatingSystem.OSArchitecture
        InstallDate            = $OperatingSystem.InstallDate
        LatestBuild            = ${NewestOnTrack}?.latest
        LatestLabel            = ${NewestOnTrack}?.releaseLabel
        # Feature-update level only. endoflife.date publishes no UBR, so this says nothing
        # about whether the monthly cumulative update is installed - that is what
        # Get-PendingWindowsUpdate answers.
        IsCurrentFeatureUpdate = if ($Cycle -and $NewestOnTrack) { $Cycle.latest -eq $NewestOnTrack.latest } else { $null }
        SupportEnd             = ${Cycle}?.support
        EndOfLife              = ${Cycle}?.eol
        IsOutOfSupport         = $IsOutOfSupport
        CheckError             = $CheckError
    }
}
