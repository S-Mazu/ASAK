#requires -Version 7.6
#requires -Modules Pester

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Functions' 'Get-NetworkConfiguration.ps1')
}

Describe 'Get-NetworkConfiguration' {
    Context 'a connected and a disconnected adapter' {
        BeforeAll {
            Mock Get-NetIPConfiguration {
                [PSCustomObject]@{
                    InterfaceAlias     = 'WLAN'
                    InterfaceIndex     = 15
                    NetAdapter         = [PSCustomObject]@{ Status = 'Up'; LinkLayerAddress = 'AA-BB-CC-DD-EE-FF' }
                    IPv4Address        = [PSCustomObject]@{ IPAddress = '192.168.1.102'; PrefixLength = 24 }
                    IPv6Address        = @()
                    IPv4DefaultGateway = [PSCustomObject]@{ NextHop = '192.168.1.1' }
                    DNSServer          = [PSCustomObject]@{ ServerAddresses = @('192.168.1.1', '8.8.8.8') }
                    NetIPv4Interface   = [PSCustomObject]@{ Dhcp = 'Enabled' }
                    NetProfile         = [PSCustomObject]@{ Name = 'Home' }
                }
                [PSCustomObject]@{
                    InterfaceAlias     = 'Ethernet 3'
                    InterfaceIndex     = 8
                    NetAdapter         = [PSCustomObject]@{ Status = 'Disconnected'; LinkLayerAddress = '11-22-33-44-55-66' }
                    IPv4Address        = [PSCustomObject]@{ IPAddress = '169.254.153.244'; PrefixLength = 16 }
                    IPv6Address        = @()
                    IPv4DefaultGateway = $null
                    DNSServer          = [PSCustomObject]@{ ServerAddresses = @('192.168.178.1') }
                    NetIPv4Interface   = [PSCustomObject]@{ Dhcp = 'Enabled' }
                    NetProfile         = $null
                }
            }
        }
        It 'returns one row per adapter, disconnected ones included' {
            $Result = @(Get-NetworkConfiguration)
            $Result.Count | Should -Be 2
            $Result[1].InterfaceAlias | Should -Be 'Ethernet 3'
            $Result[1].Status | Should -Be 'Disconnected'
        }
        It 'joins multiple DNS servers into one field' {
            (Get-NetworkConfiguration)[0].DnsServer | Should -Be '192.168.1.1, 8.8.8.8'
        }
        It 'leaves the gateway empty when the adapter has none' {
            $Result = @(Get-NetworkConfiguration)
            $Result[0].DefaultGateway | Should -Be '192.168.1.1'
            $Result[1].DefaultGateway | Should -BeNullOrEmpty
        }
    }
}
