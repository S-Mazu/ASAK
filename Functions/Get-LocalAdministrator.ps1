#requires -Version 7.6

function Get-LocalAdministrator {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # S-1-5-32-544 is the well-known SID of the built-in Administrators group. The group's
    # name is localized ("Administratoren" on German Windows); the SID is not.
    Get-LocalGroupMember -SID 'S-1-5-32-544' |
        ForEach-Object {
            # An AzureAD or domain member whose SID no longer resolves comes back with the
            # raw SID as its Name - worth flagging, since it is an orphaned grant.
            # ObjectClass is localized too, so no logic keys off it.
            [PSCustomObject]@{
                Name            = $_.Name
                Sid             = $_.SID.Value
                ObjectClass     = $_.ObjectClass
                PrincipalSource = $_.PrincipalSource
                IsUnresolved    = $_.Name -match '^S-1-'
            }
        }
}
