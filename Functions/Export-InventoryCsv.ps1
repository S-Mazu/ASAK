#requires -Version 7.6

function Export-InventoryCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$NoTypeInformation,

        [ValidateSet('UTF8', 'ASCII', 'Unicode', 'UTF7', 'UTF32', 'Default')]
        [string]$Encoding = 'UTF8',

        [string]$Delimiter = ';'
    )

    begin {
        $Collected = [System.Collections.Generic.List[PSObject]]::new()
    }
    process {
        foreach ($Item in $InputObject) {
            $Collected.Add($Item)
        }
    }
    end {
        $EncodingObject = switch ($Encoding) {
            'UTF8' { [System.Text.Encoding]::UTF8 }
            'ASCII' { [System.Text.Encoding]::ASCII }
            'Unicode' { [System.Text.Encoding]::Unicode }
            'UTF7' { [System.Text.Encoding]::UTF7 }
            'UTF32' { [System.Text.Encoding]::UTF32 }
            'Default' { [System.Text.Encoding]::Default }
        }
        $Collected | Export-Csv -Path $Path -Delimiter $Delimiter -Encoding $EncodingObject -NoTypeInformation:$NoTypeInformation
    }
}
