##################
### Step 0: set parameters required for the rest of the script
##################
#information needed to authenticate to AAD and obtain a bearer token
$tenantId = "5f1060f2-d9a4-4f59-bf9c-1dd8f3604a4b"; #the tenant ID in which the Data Collection Endpoint resides
$appId = "6a7b9c6d-c02c-458a-af79-c44caee2f698"; #the app ID created and granted permissions
$appSecret = "8n~7Q~LHDu-CiwxBWwFoZaXKW1LUDlVjv8b5a"; #the secret created for the above app

#information needed to send data to the DCR endpoint
$dcrImmutableId = "dcr-7f059bd250854f189c791182685b3f21"; #the immutableId property of the DCR object
$dceEndpoint = "https://dce-test-6u1t.westus2-1.ingest.monitor.azure.com"; #the endpoint property of the Data Collection Endpoint object

##################
### Step 1: obtain a bearer token that we'll later use to authenticate against the DCR endpoint
##################
$scope= [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
$body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
$headers = @{"Content-Type"="application/x-www-form-urlencoded"};
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
### If the above line throws an 'Unable to find type [System.Web.HttpUtility].' error, execute the line below separately from the rest of the code
# Add-Type -AssemblyName System.Web

##################
### Step 2: load up some data... in this case, generate some static data to send
##################
$currentTime = Get-Date ([datetime]::UtcNow) -Format O
$staticData = @"
[
  {
    "timeDate": "$currentTime",
    "operation": "ThisIsATestOperationName"    
  },
  {
    "timeDate": "$currentTime",
    "operation": "ThisIsAnotherTestOperationName"
  }
]
"@;



##################
### Step 3: send the data to Log Analytics via the DCR!
##################
$body = $staticData;
$headers = @{"Authorization"="Bearer $bearerToken";"Content-Type"="application/json"};
$uri = "$dceEndpoint/v1/dataCollectionRules/$dcrImmutableId/streams/Custom-MyDataStream"

$uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers
