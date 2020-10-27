param (
    [Parameter(Mandatory = $false,
        ParameterSetName = "Sub")]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceName,

    [Parameter(Mandatory)]
    [System.IO.FileInfo]$OutputFolder,

    [Parameter(Mandatory,
        ValueFromPipeline)]
    [string]$Kind,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$TemplatesKind,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [array]$DataConnector
)

switch ($PsCmdlet.ParameterSetName) {
    Sub {
        $arguments = @{
            WorkspaceName  = $WorkspaceName
            SubscriptionId = $SubscriptionId
        }
    }
    default {
        $arguments = @{
            WorkspaceName = $WorkspaceName
        }
    }
}

$date = Get-Date -Format HHmmss_ddMMyyyy

<#
        Test export path
        #>
if (Test-Path $OutputFolder) {
    Write-Verbose "Path Exists"
}
else {
    try {
        $null = New-Item -Path $OutputFolder -Force -ItemType Directory -ErrorAction Stop
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Error $ErrorMessage
        Write-Verbose $_
        Break
    }
}

<#
        Export Alert rules section
        #>
if (($Kind -like 'Alert') -or ($Kind -like 'All')) {

    $rules = Get-AzSentinelAlertRule @arguments
    if ($rules) {
        $output = @{
            Scheduled                         = @(
                $rules | Where-Object kind -eq Scheduled
            )
            Fusion                            = @(
                $rules | Where-Object kind -eq Fusion
            )
            MLBehaviorAnalytics               = @(
                $rules | Where-Object kind -eq MLBehaviorAnalytics
            )
            MicrosoftSecurityIncidentCreation = @(
                $rules | Where-Object kind -eq MicrosoftSecurityIncidentCreation
            )
        }

        try {
            $fullPath = "$($OutputFolder)AlertRules_$date.json"
            $output | ConvertTo-Json -EnumsAsStrings -Depth 15 | Out-File $fullPath -ErrorAction Stop
            Write-Output "Alert rules exported to: $fullPath"
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
            Write-Verbose $_
            Break
        }
    }
}

<#
        Export Hunting rules section
        #>
if (($Kind -like 'Hunting') -or ($Kind -like 'All')) {
    $rules = Get-AzSentinelHuntingRule @arguments

    if ($rules) {
        $output = @{
            Hunting = @()
        }
        $output.Hunting += $rules
        try {
            $fullPath = "$($OutputFolder)HuntingRules_$date.json"
            $output | ConvertTo-Json -EnumsAsStrings -Depth 15 | Out-File $fullPath -ErrorAction Stop
            Write-Output "Hunting rules exported to: $fullPath"
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
            Write-Verbose $_
            Break
        }
    }
}

<#
        Export Templates section
        #>
if (($Kind -like 'Templates') -or ($Kind -like 'All')) {

    if ($TemplatesKind) {
        $templates = Get-AzSentinelAlertRuleTemplates @arguments -Kind $TemplatesKind
    }
    else {
        $templates = Get-AzSentinelAlertRuleTemplates @arguments
    }
    $list = @()
    foreach ($template in $templates){
        foreach ($conn in $template.requiredDataConnectors){
            if ($conn.connectorId -in $DataConnector){
                $list += $template
            }
        }    
    }

    if ($list) {
        $output = @{
            Scheduled                         = @(
                $list | Where-Object kind -eq Scheduled
            )
            Fusion                            = @(
                $list | Where-Object kind -eq Fusion
            )
            MLBehaviorAnalytics               = @(
                $list | Where-Object kind -eq MLBehaviorAnalytics
            )
            MicrosoftSecurityIncidentCreation = @(
                $list | Where-Object kind -eq MicrosoftSecurityIncidentCreation
            )
        }

        try {
            $fullPath = "$($OutputFolder)Templates_$date.json"
            $output | ConvertTo-Json -EnumsAsStrings -Depth 15 | Out-File $fullPath -ErrorAction Stop
            Write-Output "Templates xported to: $fullPath"
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
            Write-Verbose $_
            Break
        }
    }
}