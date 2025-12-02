<#
.SYNOPSIS
Exports a resource inventory report with custom and system properties.

.DESCRIPTION
Retrieves all devices from LogicMonitor and exports them to a CSV file with specific custom and system properties.

.PARAMETER OutputPath
The path where the CSV file will be saved. Defaults to "resource-inventory-report.csv" in the current directory.

.EXAMPLE
.\Export-ResourceInventory.ps1

.EXAMPLE
.\Export-ResourceInventory.ps1 -OutputPath "C:\Reports\inventory.csv"

.NOTES
You must run Connect-LMAccount before running this script.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$OutputPath = "resource-inventory-report.csv"
)

# Initialize the export list
$ExportList = @()

# Get all devices with all properties
Write-Host "Retrieving all devices from LogicMonitor..." -ForegroundColor Cyan
$Devices = Get-LMDevice

Write-Host "Found $($Devices.Count) devices. Processing properties..." -ForegroundColor Cyan

# Process each device
$Counter = 0
Foreach($Device in $Devices){
    $Counter++
    if ($Counter % 100 -eq 0) {
        Write-Host "  Processed $Counter of $($Devices.Count) devices..." -ForegroundColor Gray
    }
    
    # Convert custom properties to a hashtable for easy lookup
    $CustomPropertyHash = @{}
    if ($Device.customProperties) {
        $Device.customProperties | ForEach-Object {
            $CustomPropertyHash[$_.name] = $_.value
        }
    }
    
    # Convert system properties to a hashtable for easy lookup
    $SystemPropertyHash = @{}
    if ($Device.systemProperties) {
        $Device.systemProperties | ForEach-Object {
            $SystemPropertyHash[$_.name] = $_.value
        }
    }
    
    # Build the export object with the specified properties
    $ExportList += [PSCustomObject]@{
        'system.displayname'        = $Device.displayName
        'system.hostname'           = $SystemPropertyHash['system.hostname']
        'auto.team'                 = $CustomPropertyHash['auto.team']
        'auto.credential'           = $CustomPropertyHash['auto.credential']
        'auto.environment'          = $CustomPropertyHash['auto.environment']
        'auto.department'           = $CustomPropertyHash['auto.department']
        'auto.function'             = $CustomPropertyHash['auto.function']
        'auto.type'                 = $CustomPropertyHash['auto.type']
        'auto.environment.code'     = $CustomPropertyHash['auto.environment.code']
        'auto.building'             = $CustomPropertyHash['auto.building']
        'auto.building.fullName'    = $CustomPropertyHash['auto.building.fullName']
        'auto.building.location'    = $CustomPropertyHash['auto.building.location']
        'auto.instance'             = $CustomPropertyHash['auto.instance']
        'system.collectorID'        = $Device.currentCollectorId
    }
}

Write-Host "Exporting to CSV: $OutputPath" -ForegroundColor Cyan

# Export to CSV
$ExportList | Export-Csv -NoTypeInformation -Path $OutputPath

Write-Host "Report generated successfully!" -ForegroundColor Green
Write-Host "  Total devices exported: $($ExportList.Count)" -ForegroundColor Green
Write-Host "  File location: $OutputPath" -ForegroundColor Green

