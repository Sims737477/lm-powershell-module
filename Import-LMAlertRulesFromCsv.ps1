param(
    [Parameter(Mandatory)]
    [string]$Path
)

<#
.SYNOPSIS
Imports LogicMonitor alert rules from a CSV and creates them using New-LMAlertRule.

.DESCRIPTION
Reads a CSV file of alert rules and calls New-LMAlertRule for each row.
Expected column headers:
    Name, Priority, EscalatingChainId, EscalationInterval, ResourceProperties,
    Devices, DeviceGroups, DataSource, DataSourceInstanceName, DataPoint,
    SuppressAlertClear, SuppressAlertAckSdt, LevelStr, Description

The Logic.Monitor module must already be authenticated (Connect-LMAccount or
Connect-LMAccount -SessionSync -AccountName "portal").

.EXAMPLE
.\Import-LMAlertRulesFromCsv.ps1 -Path "C:\temp\lm_alertRules.csv"
#>

if (-not (Get-Module -Name "Logic.Monitor" -ErrorAction SilentlyContinue)) {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "Logic.Monitor.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -ErrorAction Stop
    }
}

if (-not (Test-Path -LiteralPath $Path)) {
    throw "CSV file not found at path: $Path"
}

$rules = Import-Csv -Path $Path

foreach ($row in $rules) {

    $params = @{
        Name              = $row.Name
        Priority          = [int]$row.Priority
        EscalatingChainId = [int]$row.EscalatingChainId
    }

    if ($row.EscalationInterval -and $row.EscalationInterval -ne '0') {
        $params.EscalationInterval = [int]$row.EscalationInterval
    }

    if ($row.ResourceProperties) {
        $rp = @{}
        foreach ($pair in $row.ResourceProperties -split ';') {
            if (-not $pair) { continue }
            $k, $v = $pair -split '=', 2
            if ($k) { $rp[$k] = $v }
        }
        if ($rp.Count) { $params.ResourceProperties = $rp }
    }

    if ($row.Devices) {
        $params.Devices = $row.Devices -split ';'
    }

    if ($row.DeviceGroups) {
        $params.DeviceGroups = $row.DeviceGroups -split ';'
    }

    if ($row.DataSource)             { $params.DataSource             = $row.DataSource }
    if ($row.DataSourceInstanceName) { $params.DataSourceInstanceName = $row.DataSourceInstanceName }
    if ($row.DataPoint)             { $params.DataPoint              = $row.DataPoint }

    if ($row.SuppressAlertClear)  { $params.SuppressAlertClear  = [bool]$row.SuppressAlertClear }
    if ($row.SuppressAlertAckSdt) { $params.SuppressAlertAckSdt = [bool]$row.SuppressAlertAckSdt }
    if ($row.LevelStr)            { $params.LevelStr            = $row.LevelStr }
    if ($row.Description)         { $params.Description         = $row.Description }

    New-LMAlertRule @params
}


