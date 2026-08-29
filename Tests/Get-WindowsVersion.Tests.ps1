#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-RegistryValue.ps1')
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-WindowsVersion.ps1')

    $Script:Catalog = @(
        [PSCustomObject]@{ cycle = '11-26h1-e'; releaseLabel = '11 26H1 (E)'; latest = '10.0.28000'; releaseDate = '2026-02-10'; eol = '2029-03-13'; support = '2029-03-13' }
        [PSCustomObject]@{ cycle = '11-26h1-w'; releaseLabel = '11 26H1 (W)'; latest = '10.0.28000'; releaseDate = '2026-02-10'; eol = '2028-03-14'; support = '2028-03-14' }
        [PSCustomObject]@{ cycle = '11-25h2-e'; releaseLabel = '11 25H2 (E)'; latest = '10.0.26200'; releaseDate = '2025-09-30'; eol = '2028-10-10'; support = '2028-10-10' }
        [PSCustomObject]@{ cycle = '11-25h2-w'; releaseLabel = '11 25H2 (W)'; latest = '10.0.26200'; releaseDate = '2025-09-30'; eol = '2027-10-12'; support = '2027-10-12' }
        [PSCustomObject]@{ cycle = '10-22h2-w'; releaseLabel = '10 22H2 (W)'; latest = '10.0.19045'; releaseDate = '2022-10-18'; eol = '2025-10-14'; support = '2025-10-14' }
    )
}

Describe 'Get-WindowsVersion' {
    BeforeAll {
        Mock Get-CimInstance {
            [PSCustomObject]@{
                Caption        = 'Microsoft Windows 11 Business'
                OSArchitecture = '64-Bit'
                InstallDate    = [datetime]'2025-01-15'
            }
        }
    }

    Context 'a current Professional machine' {
        BeforeAll {
            Mock Get-RegistryValue { '25H2' } -ParameterFilter { $Name -eq 'DisplayVersion' }
            Mock Get-RegistryValue { '26200' } -ParameterFilter { $Name -eq 'CurrentBuild' }
            Mock Get-RegistryValue { 9106 } -ParameterFilter { $Name -eq 'UBR' }
            Mock Get-RegistryValue { 'Professional' } -ParameterFilter { $Name -eq 'EditionID' }
            Mock Get-RegistryValue { 'Client' } -ParameterFilter { $Name -eq 'InstallationType' }
            Mock Invoke-RestMethod { $Script:Catalog }
        }
        It 'reports the local identity from Caption and the registry' {
            $Result = Get-WindowsVersion
            $Result.Caption | Should -Be 'Microsoft Windows 11 Business'
            $Result.DisplayVersion | Should -Be '25H2'
            $Result.Build | Should -Be '26200'
            $Result.Ubr | Should -Be 9106
        }
        It 'picks the consumer track, not the Enterprise one with the same build' {
            (Get-WindowsVersion).EndOfLife | Should -Be '2027-10-12'
        }
        It 'flags the machine as behind the newest feature update' {
            $Result = Get-WindowsVersion
            $Result.LatestBuild | Should -Be '10.0.28000'
            $Result.LatestLabel | Should -Be '11 26H1 (W)'
            $Result.IsCurrentFeatureUpdate | Should -BeFalse
        }
        It 'queries the client product, not windows-server' {
            Get-WindowsVersion | Out-Null
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://endoflife.date/api/windows.json' }
        }
    }

    Context 'an Enterprise machine on the newest release' {
        BeforeAll {
            Mock Get-RegistryValue { '26H1' } -ParameterFilter { $Name -eq 'DisplayVersion' }
            Mock Get-RegistryValue { '28000' } -ParameterFilter { $Name -eq 'CurrentBuild' }
            Mock Get-RegistryValue { 1 } -ParameterFilter { $Name -eq 'UBR' }
            Mock Get-RegistryValue { 'Enterprise' } -ParameterFilter { $Name -eq 'EditionID' }
            Mock Get-RegistryValue { 'Client' } -ParameterFilter { $Name -eq 'InstallationType' }
            Mock Invoke-RestMethod { $Script:Catalog }
        }
        It 'picks the Enterprise track and reports the machine as current' {
            $Result = Get-WindowsVersion
            $Result.EndOfLife | Should -Be '2029-03-13'
            $Result.IsCurrentFeatureUpdate | Should -BeTrue
        }
    }

    Context 'a Windows 10 machine past its end of life' {
        BeforeAll {
            Mock Get-RegistryValue { '22H2' } -ParameterFilter { $Name -eq 'DisplayVersion' }
            Mock Get-RegistryValue { '19045' } -ParameterFilter { $Name -eq 'CurrentBuild' }
            Mock Get-RegistryValue { 5011 } -ParameterFilter { $Name -eq 'UBR' }
            Mock Get-RegistryValue { 'Professional' } -ParameterFilter { $Name -eq 'EditionID' }
            Mock Get-RegistryValue { 'Client' } -ParameterFilter { $Name -eq 'InstallationType' }
            Mock Invoke-RestMethod { $Script:Catalog }
        }
        It 'flags it out of support and compares against Windows 10, not Windows 11' {
            $Result = Get-WindowsVersion
            $Result.IsOutOfSupport | Should -BeTrue
            $Result.LatestBuild | Should -Be '10.0.19045'
        }
    }

    Context 'a Server installation' {
        BeforeAll {
            Mock Get-RegistryValue { '21H2' } -ParameterFilter { $Name -eq 'DisplayVersion' }
            Mock Get-RegistryValue { '20348' } -ParameterFilter { $Name -eq 'CurrentBuild' }
            Mock Get-RegistryValue { 1 } -ParameterFilter { $Name -eq 'UBR' }
            Mock Get-RegistryValue { 'ServerStandard' } -ParameterFilter { $Name -eq 'EditionID' }
            Mock Get-RegistryValue { 'Server' } -ParameterFilter { $Name -eq 'InstallationType' }
            Mock Invoke-RestMethod { @() }
        }
        It 'queries the windows-server product instead' {
            Get-WindowsVersion | Out-Null
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter { $Uri -eq 'https://endoflife.date/api/windows-server.json' }
        }
    }

    Context 'the machine is offline' {
        BeforeAll {
            Mock Get-RegistryValue { '25H2' } -ParameterFilter { $Name -eq 'DisplayVersion' }
            Mock Get-RegistryValue { '26200' } -ParameterFilter { $Name -eq 'CurrentBuild' }
            Mock Get-RegistryValue { 9106 } -ParameterFilter { $Name -eq 'UBR' }
            Mock Get-RegistryValue { 'Professional' } -ParameterFilter { $Name -eq 'EditionID' }
            Mock Get-RegistryValue { 'Client' } -ParameterFilter { $Name -eq 'InstallationType' }
            Mock Invoke-RestMethod { throw 'No such host is known.' }
        }
        It 'records the failure and still returns the local half' {
            $Result = Get-WindowsVersion
            $Result.CheckError | Should -Be 'No such host is known.'
            $Result.DisplayVersion | Should -Be '25H2'
            $Result.LatestBuild | Should -BeNullOrEmpty
            $Result.IsCurrentFeatureUpdate | Should -BeNullOrEmpty
        }
    }

    Context 'the build is not in the published catalog' {
        BeforeAll {
            Mock Get-RegistryValue { '99H9' } -ParameterFilter { $Name -eq 'DisplayVersion' }
            Mock Get-RegistryValue { '99999' } -ParameterFilter { $Name -eq 'CurrentBuild' }
            Mock Get-RegistryValue { 1 } -ParameterFilter { $Name -eq 'UBR' }
            Mock Get-RegistryValue { 'Professional' } -ParameterFilter { $Name -eq 'EditionID' }
            Mock Get-RegistryValue { 'Client' } -ParameterFilter { $Name -eq 'InstallationType' }
            Mock Invoke-RestMethod { $Script:Catalog }
        }
        It 'says so in CheckError rather than guessing' {
            (Get-WindowsVersion).CheckError | Should -Be 'No published release matches build 99999.'
        }
    }
}
