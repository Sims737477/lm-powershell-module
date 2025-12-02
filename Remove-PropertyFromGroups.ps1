<#
.SYNOPSIS
Removes a specific custom property from all device groups that have it.

.DESCRIPTION
Finds all device groups that have a specified custom property and removes that property from them.

.PARAMETER PropertyName
The name of the custom property to remove from device groups.

.PARAMETER WhatIf
Shows what would happen if the script runs without actually making changes.

.EXAMPLE
.\Remove-PropertyFromGroups.ps1 -PropertyName "old.property"

.EXAMPLE
.\Remove-PropertyFromGroups.ps1 -PropertyName "deprecated.tag" -WhatIf

.NOTES
You must run Connect-LMAccount before running this script.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [String]$PropertyName
)

Write-Host "Searching for device groups with property: $PropertyName" -ForegroundColor Cyan

# Get all device groups
Write-Host "Retrieving all device groups..." -ForegroundColor Gray
$AllGroups = Get-LMDeviceGroup

Write-Host "Found $($AllGroups.Count) total device groups. Checking for property..." -ForegroundColor Gray

# Find groups that have the specified property
$GroupsWithProperty = @()

$Counter = 0
foreach ($Group in $AllGroups) {
    $Counter++
    if ($Counter % 50 -eq 0) {
        Write-Host "  Checked $Counter of $($AllGroups.Count) groups..." -ForegroundColor Gray
    }
    
    # Check if this group has the specified property
    if ($Group.customProperties) {
        $HasProperty = $Group.customProperties | Where-Object { $_.name -eq $PropertyName }
        if ($HasProperty) {
            $GroupsWithProperty += [PSCustomObject]@{
                Id       = $Group.id
                Name     = $Group.name
                FullPath = $Group.fullPath
                PropertyValue = $HasProperty.value
            }
        }
    }
}

Write-Host ""
Write-Host "Found $($GroupsWithProperty.Count) groups with property '$PropertyName'" -ForegroundColor Yellow
Write-Host ""

if ($GroupsWithProperty.Count -eq 0) {
    Write-Host "No groups found with this property. Exiting." -ForegroundColor Green
    exit
}

# Display the groups that will be affected
Write-Host "Groups that will have property '$PropertyName' removed:" -ForegroundColor Yellow
Write-Host "=" * 80
$GroupsWithProperty | Format-Table -Property Id, Name, FullPath, PropertyValue -AutoSize
Write-Host "=" * 80
Write-Host ""

# Confirm before proceeding (unless -WhatIf is specified)
if (-not $WhatIfPreference) {
    $Confirmation = Read-Host "Do you want to proceed with removing this property from $($GroupsWithProperty.Count) groups? (yes/no)"
    if ($Confirmation -notlike "y*") {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit
    }
}

# Remove the property from each group
Write-Host ""
Write-Host "Removing property from groups..." -ForegroundColor Cyan
$SuccessCount = 0
$ErrorCount = 0

foreach ($Group in $GroupsWithProperty) {
    try {
        if ($PSCmdlet.ShouldProcess("Group: $($Group.Name) (ID: $($Group.Id))", "Remove property '$PropertyName'")) {
            Remove-LMDeviceGroupProperty -Id $Group.Id -PropertyName $PropertyName -Confirm:$false
            Write-Host "  ✓ Removed from: $($Group.FullPath)" -ForegroundColor Green
            $SuccessCount++
        }
    }
    catch {
        Write-Host "  ✗ Failed to remove from: $($Group.FullPath) - Error: $_" -ForegroundColor Red
        $ErrorCount++
    }
}

# Summary
Write-Host ""
Write-Host "=" * 80
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Property Name: $PropertyName" -ForegroundColor White
Write-Host "  Groups Found: $($GroupsWithProperty.Count)" -ForegroundColor White
Write-Host "  Successfully Removed: $SuccessCount" -ForegroundColor Green
if ($ErrorCount -gt 0) {
    Write-Host "  Errors: $ErrorCount" -ForegroundColor Red
}
Write-Host "=" * 80

