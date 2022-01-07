$data = @()
$data += 'Kind,Display Name,Connector,Query'

$files =  Get-ChildItem -Path '.\Hunting Queries\SecurityEvent' -Filter *.yaml 

$files += Get-ChildItem -Path '.\Hunting Queries\MultipleDataSources' -Filter *.yaml 

$events = @()

foreach ($item in $files) {
    $EventIDs = ""

    Write-Host "Processing file "+ $item.FullName

    $content = Get-Content -Path $item.FullName 

    if (($content | Select-String  -Pattern 'SecurityEvent' | ForEach-Object { $_.Matches.Value }) -ne $null){
        
            Write-Host "Processing rule template "+ $content

            if (($content | Select-String  -Pattern 'EventID == \d{4}' | ForEach-Object { $_.Matches.Value }) -ne $null){
            
                $EventIDs = ($content | Select-String  -Pattern 'EventID == \d{4}' | ForEach-Object { $_.Matches.Value }).split('==')[1]
                
                if ($events -notcontains $EventIDs){
                    $events += $EventIDs
                }

            } elseif (($content | Select-String  -Pattern "EventID == '\d{4}'" | ForEach-Object { $_.Matches.Value }) -ne $null) {
                
                $EventIDs = "-" + ($content | Select-String  -Pattern "EventID == '\d{4}'" | ForEach-Object { $_.Matches.Value }).split('==')[1]
                
                if ($events -notcontains $EventIDs){
                    $events += $EventIDs
                }

            } elseif (($content | Select-String  -Pattern "EventID in \(([^\)]+)" | ForEach-Object { $_.Matches.Value }) -ne $null) {
            
                Write-Host "Inside EventID in clause"
            
                $EventIDs += "-" +  ($content | Select-String  -Pattern "EventID in \(([^\)]+)" | ForEach-Object { $_.Matches.Value }).split("(")[1]

                if ($events -notcontains $EventIDs){
                    $events += $EventIDs
                }

            } elseif ( ($content | Select-String  -Pattern "EventID==\d{4}" | ForEach-Object { $_.Matches.Value }) -ne $null) {
            
                Write-Host "Inside EventID== in clause"
        
                $EventIDs += "-" +  ($content | Select-String  -Pattern "EventID==\d{4}" | ForEach-Object { $_.Matches.Value }).split("==")[1]
          
                if ($events -notcontains $EventIDs){
                    $events += $EventIDs
                }
          
            }

            $data += $item.Name +','+$EventIDs
    }
}

Write-Host "Done!"

$date = Get-Date -Format HHmmss_ddMMyyyy

Write-Host "Unique Event IDs are:" $events

$data > "SecurityEvents_$date.csv"