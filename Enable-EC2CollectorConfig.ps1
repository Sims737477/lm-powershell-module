<#
.SYNOPSIS
Enables EC2 normalCollectorConfig for AWS account device groups.

.DESCRIPTION
This script finds all child device groups under a specified parent group ID that have 
EC2 normalCollectorConfig disabled and enables it using the ExtraPatch functionality.

.PARAMETER ParentGroupId
The ID of the parent device group containing AWS accounts. Default is 7776.

.PARAMETER AccountFilter
Optional array of account names to filter. Useful for testing on specific accounts.
Supports wildcards.

.PARAMETER WhatIf
Shows what would be changed without making any changes.

.EXAMPLE
# Test on specific accounts
.\Enable-EC2CollectorConfig.ps1 -ParentGroupId 7776 -AccountFilter "Infrastructure Lab","VDC Non-Production*"

.EXAMPLE
# Run against all accounts under parent group
.\Enable-EC2CollectorConfig.ps1 -ParentGroupId 7776

.EXAMPLE
# See what would change without making changes
.\Enable-EC2CollectorConfig.ps1 -ParentGroupId 7776 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [int]$ParentGroupId = 7776,
    
    [Parameter()]
    [string[]]$AccountFilter
)

Write-Host "`n=== EC2 Collector Config Enabler ===" -ForegroundColor Cyan
Write-Host "Parent Group ID: $ParentGroupId" -ForegroundColor Gray

# Step 1: Get child groups
Write-Host "`nStep 1: Getting child groups..." -ForegroundColor Cyan
$childGroups = Get-LMDeviceGroupGroups -Id $ParentGroupId
Write-Host "  Found $($childGroups.Count) child groups" -ForegroundColor Gray

# Step 2: Apply account filter if specified
if ($AccountFilter) {
    Write-Host "`nApplying account filter..." -ForegroundColor Cyan
    $filteredGroups = @()
    foreach ($filter in $AccountFilter) {
        $filteredGroups += $childGroups | Where-Object { $_.name -like $filter }
    }
    $childGroups = $filteredGroups
    Write-Host "  Filtered to $($childGroups.Count) groups" -ForegroundColor Gray
}

# Step 3: Find targets with EC2 normalCollectorConfig disabled
Write-Host "`nStep 2: Checking EC2 normalCollectorConfig status..." -ForegroundColor Cyan
$targets = $childGroups | ForEach-Object { 
    $g = Get-LMDeviceGroup -Id $_.id
    $extraObj = ($g.extra -is [string]) ? ($g.extra | ConvertFrom-Json) : $g.extra
    if ($extraObj -and $extraObj.services -and $extraObj.services.EC2 -and $extraObj.services.EC2.normalCollectorConfig -and ($extraObj.services.EC2.normalCollectorConfig.enable -eq $false)) { 
        $g 
    }
}

Write-Host "  Found $($targets.Count) groups with EC2 normalCollectorConfig DISABLED" -ForegroundColor Yellow

if ($targets.Count -eq 0) {
    Write-Host "`nNo groups need updating. All accounts already have EC2 normalCollectorConfig enabled!" -ForegroundColor Green
    exit 0
}

# Display targets
Write-Host "`nGroups that will be updated:" -ForegroundColor Cyan
$targets | ForEach-Object { Write-Host "  - $($_.name) (ID: $($_.id))" -ForegroundColor Gray }

# Step 4: Enable EC2 normalCollectorConfig
Write-Host "`nStep 3: Enabling EC2 normalCollectorConfig..." -ForegroundColor Cyan

$i = 0
$targets | ForEach-Object {
    $i++
    $groupName = $_.name
    
    if ($PSCmdlet.ShouldProcess("$groupName (ID: $($_.id))", "Enable EC2 normalCollectorConfig")) {
        Write-Host "  [$i/$($targets.Count)] Updating: $groupName" -ForegroundColor Gray
        
        Set-LMDeviceGroup -Id $_.id -ExtraPatch @{
            services = @{
                EC2 = @{
                    normalCollectorConfig = @{
                        enable = $true
                    }
                }
            }
        } | Out-Null
    }
}

if (-not $WhatIfPreference) {
    Write-Host "`nComplete! Enabled EC2 normalCollectorConfig for $($targets.Count) groups." -ForegroundColor Green
}

Write-Host ""

