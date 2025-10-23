function ConvertTo-HashtableDeep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )

    if ($null -eq $InputObject) { return @{} }

    if ($InputObject -is [hashtable]) {
        $result = @{}
        foreach ($k in $InputObject.Keys) {
            $result[$k] = ConvertTo-HashtableDeep -InputObject $InputObject[$k]
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($k in $InputObject.Keys) {
            $result[$k] = ConvertTo-HashtableDeep -InputObject $InputObject[$k]
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $list = @()
        foreach ($item in $InputObject) { $list += ,(ConvertTo-HashtableDeep -InputObject $item) }
        return $list
    }

    if ($InputObject -is [pscustomobject]) {
        # Convert PSCustomObject to hashtable recursively
        return ($InputObject | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable)
    }

    return $InputObject
}

function Merge-HashtableDeep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Base,

        [Parameter(Mandatory)]
        [hashtable]$Patch,

        [ValidateSet('Replace','Concat')]
        [string]$ArrayStrategy = 'Replace'
    )

    foreach ($key in $Patch.Keys) {
        $patchValue = $Patch[$key]
        if (-not $Base.ContainsKey($key)) {
            $Base[$key] = $patchValue
            continue
        }

        $baseValue = $Base[$key]

        $isBaseHash  = $baseValue -is [hashtable] -or $baseValue -is [System.Collections.IDictionary]
        $isPatchHash = $patchValue -is [hashtable] -or $patchValue -is [System.Collections.IDictionary]

        if ($isBaseHash -and $isPatchHash) {
            $baseHash  = ($baseValue -is [hashtable])  ? $baseValue  : (@{} + $baseValue)
            $patchHash = ($patchValue -is [hashtable]) ? $patchValue : (@{} + $patchValue)
            Merge-HashtableDeep -Base $baseHash -Patch $patchHash -ArrayStrategy $ArrayStrategy | Out-Null
            $Base[$key] = $baseHash
            continue
        }

        $isBaseArray  = $baseValue -is [System.Collections.IEnumerable] -and -not ($baseValue -is [string])
        $isPatchArray = $patchValue -is [System.Collections.IEnumerable] -and -not ($patchValue -is [string])

        if ($isBaseArray -and $isPatchArray) {
            if ($ArrayStrategy -eq 'Concat') {
                $Base[$key] = @($baseValue + $patchValue)
            }
            else {
                $Base[$key] = @($patchValue)
            }
            continue
        }

        # Primitive or type mismatch -> replace
        $Base[$key] = $patchValue
    }

    return $Base
}


