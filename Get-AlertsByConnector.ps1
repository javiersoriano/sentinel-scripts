$data = @()
$data += 'Kind,Display Name,Connector,Tactics'

$alertTemplates = Get-AzSentinelAlertRuleTemplates -WorkspaceName sorisentinel

foreach ($item in $alertTemplates) {
    Write-Host "Processing rule template "+ $item.displayName
    $connectors = ""
    foreach ($conn in $item.requiredDataConnectors){
        $connectors += $conn.connectorId+" | "
    }

    $data += $item.kind+','+$item.displayName+','+$connectors+','+$item.Tactics
     
}

Write-Host "Done!"

$date = Get-Date -Format HHmmss_ddMMyyyy

$data > "AnalyticsRulesTemplates_$date.csv"