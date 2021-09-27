$data = @()
$data += 'Kind,Display Name,Connector,Query'

$alertTemplates = Get-AzSentinelAlertRuleTemplates -WorkspaceName sorisentinel

foreach ($item in $alertTemplates) {
    $EventIDs = ""
    foreach ($conn in $item.requiredDataConnectors.DataTypes){
                
        if ($conn -contains "SecurityEvent"){
        
            Write-Host "Processing rule template "+ $item.displayName

            if (($item | Select-String -InputObject {$_.Query} -Pattern 'EventID == \d{4}' | ForEach-Object { $_.Matches.Value }) -ne $null){
            
                $EventIDs = ($item | Select-String -InputObject {$_.Query} -Pattern 'EventID == \d{4}' | ForEach-Object { $_.Matches.Value }).split('==')[1]
            
            } elseif (($item | Select-String -InputObject {$_.Query} -Pattern "EventID == '\d{4}'" | ForEach-Object { $_.Matches.Value }) -ne $null) {
                
                $EventIDs = "-" + ($item | Select-String -InputObject {$_.Query} -Pattern "EventID == '\d{4}'" | ForEach-Object { $_.Matches.Value }).split('==')[1]
            
            } elseif (($item | Select-String -InputObject {$_.Query} -Pattern "EventID in \(([^\)]+)" | ForEach-Object { $_.Matches.Value }) -ne $null) {
            
                Write-Host "Inside EventID in clause"
            
                $EventIDs += "-" +  ($item | Select-String -InputObject {$_.Query} -Pattern "EventID in \(([^\)]+)" | ForEach-Object { $_.Matches.Value }).split("(")[1]

            } elseif ( ($item | Select-String -InputObject {$_.Query} -Pattern "EventID==\d{4}" | ForEach-Object { $_.Matches.Value }) -ne $null) {
            
                Write-Host "Inside EventID== in clause"
        
                $EventIDs += "-" +  ($item | Select-String -InputObject {$_.Query} -Pattern "EventID==\d{4}" | ForEach-Object { $_.Matches.Value }).split("==")[1]
            }

            $data += $item.kind+','+$item.displayName+','+$conn+','+$EventIDs

            Break
        }
    }
     
}

Write-Host "Done!"

$date = Get-Date -Format HHmmss_ddMMyyyy

$data > "SecurityEvents_$date.csv"