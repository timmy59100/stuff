#requires -Version 3.0
function New-AemApiAccessToken
{
	param
	(
		[string]$apiUrl,
		[string]$apiKey,
		[string]$apiSecretKey
	)

	# Specify security protocols
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

	# Convert password to secure string
	$securePassword = ConvertTo-SecureString -String 'public' -AsPlainText -Force

	# Define parameters for Invoke-WebRequest cmdlet
	$params = @{
		Credential	=	New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('public-client', $securePassword)
		Uri			=	'{0}/auth/oauth/token' -f $apiUrl
		Method      =	'POST'
		ContentType = 	'application/x-www-form-urlencoded'
		Body        = 	'grant_type=password&username={0}&password={1}' -f $apiKey, $apiSecretKey
	}
	
	# Request access token
	try {(Invoke-WebRequest @params | ConvertFrom-Json).access_token}
	catch {$_.Exception}
}

function New-AemApiRequest
{
	param 
	(
		[string]$apiUrl,
		[string]$apiAccessToken,
		[string]$apiMethod,
		[string]$apiRequest,
		[string]$apiRequestBody
	)

	# Define parameters for Invoke-WebRequest cmdlet
	$params = @{
		Uri         =	'{0}/api{1}' -f $apiUrl, $apiRequest
		Method      =	$apiMethod
		ContentType	= 	'application/json'
		Headers     =	@{
			'Authorization'	=	'Bearer {0}' -f $apiAccessToken
		}
	}

	# Add body to parameters if present
	If ($apiRequestBody) {$params.Add('Body',$apiRequestBody)}

	# Make request
	try {Invoke-RestMethod @params}
	catch{write-host $_.Exception}
}

function Get-Site {
    param (

    [Parameter(Mandatory=$false)]
    $Kunde
	)
	
# Define parameters
$params = @{
	apiUrl         	=	'https://merlot-api.centrastage.net'
	apiKey         	=	'DVVCHUVEGJU67CP2D8DOA0H2TVA672TA'
	apiSecretKey   	=	'LSGLEH7PNNUHQBT09U3JQ05HGD8I3L7O'
	apiMethod      	=	'GET'
	apiRequest		=	'/v2/account/sites'
	apiRequestBody	=	''
}

$result = New-AemApiRequest @params -ApiAccessToken $apiAccessToken
if($Kunde -eq $null)
{$Site = $result.sites  }
else {
	$Site = $result.sites | Where-Object {$_.name -like $Kunde}
}

$Site
}

function Get-Devices {
    param (
	[CmdletBinding()]
    [Parameter(Mandatory=$False, ValueFromPipeline = $true)]
    $Kunde,
    [Parameter(Mandatory=$False)]
    $Devicetype

	)
	$params = @{
		apiUrl         	=	'https://merlot-api.centrastage.net'
		apiMethod      	=	'GET'
		apiRequest		=	'/v2/account/devices'
		apiRequestBody	=	''
	}
	
	$site = $Kunde
	if ($site -ne $null) {$params['apiRequest'] = "/v2/site/" + $site.uid + "/devices"}
	
	$result = New-AemApiRequest @params -ApiAccessToken $apiAccessToken

	$AllResult += $result.devices
	while ($null-ne $result.pageDetails.nextPageURL) {
		$params['apiRequest'] = ($result.pageDetails.nextPageURL).Replace("https://merlot-api.centrastage.net/api","")
		$result = New-AemApiRequest @params -ApiAccessToken $apiAccessToken	
		$AllResult += $result.devices
	}

	if ($devicetype) {
		$result.devices | Where-Object {$_.Devicetype.category -eq $Devicetype}
	}
	else {
		$AllResult 
	}
	



}

$params = @{
	apiUrl         	=	'https://merlot-api.centrastage.net'
	apiKey         	=	'DVVCHUVEGJU67CP2D8DOA0H2TVA672TA'
	apiSecretKey   	=	'LSGLEH7PNNUHQBT09U3JQ05HGD8I3L7O'
	apiMethod      	=	'GET'
	apiRequest		=	'/v2/account/devices'
	apiRequestBody	=	''
}

# Call New-AemApiAccessToken function using defined parameters 
$apiAccessToken = New-AemApiAccessToken @params

# Call New-AemApiRequest function using defined parameters
#$result = New-AemApiRequest @params -ApiAccessToken $apiAccessToken


#Get-Devices -Kunde 'IT-S GmbH'


(Get-Devices).count #| select hostname