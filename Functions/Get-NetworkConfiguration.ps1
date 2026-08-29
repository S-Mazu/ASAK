#requires -Version 7.6

function Get-NetworkConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # Every adapter is returned, virtual and disconnected ones included: filtering them out
    # would also hide a misconfigured NIC. Status shows which one is actually live.
    Get-NetIPConfiguration -Detailed -All |
        ForEach-Object {
            $Configuration = $_

            # A disconnected adapter reports its addresses as $null on some fields and as an
            # empty array on others, and neither survives a bare member access under
            # Set-StrictMode. Wrapping in @() and dropping the nulls normalises both to an
            # empty collection, which the pipeline below then yields nothing from.
            $IPv4 = @($Configuration.IPv4Address).Where({ $null -ne $_ })
            $IPv6 = @($Configuration.IPv6Address).Where({ $null -ne $_ })
            $Gateway = @($Configuration.IPv4DefaultGateway).Where({ $null -ne $_ })
            $Dns = @($Configuration.DNSServer).Where({ $null -ne $_ })

            # An adapter can hold several addresses, gateways or DNS servers at once, so each
            # of those collapses to one delimited string rather than multiplying the rows.
            [PSCustomObject]@{
                InterfaceAlias    = $Configuration.InterfaceAlias
                InterfaceIndex    = $Configuration.InterfaceIndex
                Status            = ${Configuration}?.NetAdapter?.Status
                MacAddress        = ${Configuration}?.NetAdapter?.LinkLayerAddress
                IPv4Address       = ($IPv4 | ForEach-Object { $_.IPAddress }) -join ', '
                PrefixLength      = ($IPv4 | ForEach-Object { $_.PrefixLength }) -join ', '
                IPv6Address       = ($IPv6 | ForEach-Object { $_.IPAddress }) -join ', '
                DefaultGateway    = ($Gateway | ForEach-Object { $_.NextHop }) -join ', '
                DnsServer         = ($Dns | ForEach-Object { $_.ServerAddresses }) -join ', '
                DhcpEnabled       = ${Configuration}?.NetIPv4Interface?.Dhcp
                ConnectionProfile = ${Configuration}?.NetProfile?.Name
            }
        }
}
