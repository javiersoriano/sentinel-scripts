PARAM(
    [Parameter(Mandatory=$true)]$TableName, # The log lanlyics table you wish to have in ADX
    [Parameter(Mandatory=$true)]$WorkspaceId # The log lanlyics WorkspaceId
)

$query = $TableName + ' | getschema | project ColumnName, DataType'

$output = (Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $query).Results

$TableExpandFunction = $TableName + 'Expand'
$TableRaw = $TableName + 'Raw'
$RawMapping = $TableRaw + 'Mapping'

$FirstCommand = @()
$ThirdCommand = @()

foreach ($record in $output) {
    if ($record.DataType -eq 'System.DateTime') {
        $dataType = 'datetime'
        $ThirdCommand += $record.ColumnName + " = todatetime(events." + $record.ColumnName + "),"
    } else {
        $dataType = 'string'
        $ThirdCommand += $record.ColumnName + " = tostring(events." + $record.ColumnName + "),"
    }
    $FirstCommand += $record.ColumnName + ":" + "$dataType" + ","    
}

$schema = ($FirstCommand -join '') -replace ',$'
$function = ($ThirdCommand -join '') -replace ',$'

$CreateRawTable = @'
.create table {0} (Records:dynamic)
'@ -f $TableRaw

$CreateRawMapping = @'
.create table {0} ingestion json mapping '{1}' '[{{"column":"Records","Properties":{{"path":"$.records"}}}}]'
'@ -f $TableRaw, $RawMapping

$CreateRetention = @'
.alter-merge table {0} policy retention softdelete = 0d
'@ -f $TableRaw

$CreateTable = @'
.create table {0} ({1})
'@ -f $TableName, $schema

$CreateFunction = @'
.create-or-alter function {0} {{
    {1}
| mv-expand events = Records
| project 
{2}
}}
'@ -f $TableExpandFunction, $TableRaw, $function

$CreatePolicyUpdate = @'
.alter table {0} policy update @'[{{"Source": "{1}", "Query": "{2}()", "IsEnabled": "True", "IsTransactional": true}}]'
'@ -f $TableName, $TableRaw, $TableExpandFunction

Write-Host -ForegroundColor Red 'Copy and run the following commands (one by one), on your Azure Data Explorer cluster query window to create the table, mappings and update policy:'
Write-Host -ForegroundColor Green $CreateRawTable
Write-Host `r
Write-Host -ForegroundColor Green $CreateRawMapping
Write-Host `r
Write-Host -ForegroundColor Green $CreateRetention
Write-Host `r
Write-Host -ForegroundColor Green $CreateTable
Write-Host `r
Write-Host -ForegroundColor Green $CreateFunction
Write-Host `r
Write-Host -ForegroundColor Green $CreatePolicyUpdate