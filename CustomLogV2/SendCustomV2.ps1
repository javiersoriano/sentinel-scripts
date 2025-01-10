##################
### Step 0: set parameters required for the rest of the script
##################
#information needed to authenticate to AAD and obtain a bearer token
$tenantId = "*************************"; #the tenant ID in which the Data Collection Endpoint resides
$appId = "***********************"; #the app ID created and granted permissions
$appSecret = ******************"; #the secret created for the above app

#information needed to send data to the DCR endpoint
$dcrImmutableId = "dcr-****************"; #the immutableId property of the DCR object
$dceEndpoint = "https://************.ingest.monitor.azure.com"; #the endpoint property of the Data Collection Endpoint object

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
$staticData1 = @"
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

$staticData2 = @"
[
  {
    "timeDate2": "$currentTime",
    "operation2": "ThisIsATestOperationName"    
  },
  {
    "timeDate2": "$currentTime",
    "operation2": "ThisIsAnotherTestOperationName"
  }
]
"@;


##################
### Step 3: send the data to Log Analytics via the DCR!
##################
$body1 = $staticData1;
$body2 = $staticData2;
$headers = @{"Authorization"="Bearer $bearerToken";"Content-Type"="application/json"};
$uri1 = "$dceEndpoint/v1/dataCollectionRules/$dcrImmutableId/streams/Custom-MyDataStream"
$uri2 = "$dceEndpoint/v1/dataCollectionRules/$dcrImmutableId/streams/Custom-MyDataStream2"

$uploadResponse1 = Invoke-RestMethod -Uri $uri1 -Method "Post" -Body $body1 -Headers $headers
$uploadResponse2 = Invoke-RestMethod -Uri $uri2 -Method "Post" -Body $body2 -Headers $headers


