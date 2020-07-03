


<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>

####################################################

#$ImportPath = Read-Host -Prompt "Please specify a path to a JSON file to import data from e.g. C:\IntuneOutput\Policies\policy.json"

#$ImportPath = "C:\Users\mapottin\Documents\GitHub\BYOD-UK-Blueprint-Auto\JSON\CA JSON"

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ImportPath = $ScriptDir+"\JSON\CA JSON"

#$AADAllowGroup = "PAW-Mgmt-Accounts"

#$AADExcludeGroup = "PAW-Break-Glass-Accounts"


function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User
)

$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

$tenant = $userUpn.Host

Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }

# Getting path to ActiveDirectory Assemblies
# If the module count is greater than 1 find the latest version

    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]

        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            # Checking if there are multiple versions of the same module found

            if($AadModule.count -gt 1){

            $aadModule = $AadModule | select -Unique

            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null


$CAAppReg = get-AzureADApplication -filter "DisplayName eq 'BYOD UK BP PowerShell Tool'"

    if ($CAAppReg -eq $null)
        { 
           Write-Host "Run AppRegistration scipt" -ForegroundColor Red
           
        }
    else 
        {
            $clientId = $CAAppReg.appid

        }
        
#$clientId = "10ee97b8-2f71-4e84-a4fa-fa65c08e1d45"

$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

$resourceAppIdURI = "https://graph.microsoft.com"

$authority = "https://login.microsoftonline.com/$Tenant"

    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
    # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        # If the accesstoken is valid then create the authentication header

        if($authResult.AccessToken){

        # Creating header for Authorization token

        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $authResult.AccessToken
            'ExpiresOn'=$authResult.ExpiresOn
            }

        return $authHeader

        }

        else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}

####################################################

Function Test-JSON(){

<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-JSON
#>

param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){
    
    Write-Host "Provided JSON isn't in valid JSON format" -f Red
    break

    }

}

####################################################

Function Add-ConditionalAccessPolicy(){

<#
.SYNOPSIS
This function is used to add an Conditional Access policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a Conditional Access policy
.EXAMPLE
Add-ConditionalAccessPolicy -JSON $JSON
Adds a Conditional Access policy in the organization
.NOTES
NAME: Add-ConditionalAccessPolicy
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "conditionalAccess/policies"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for a Conditional Access policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

        }

    }

    catch {

    Write-Host
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Get-AADGroup(){



<#

.SYNOPSIS

This function is used to get AAD Groups from the Graph API REST interface

.DESCRIPTION

The function connects to the Graph API Interface and gets any Groups registered with AAD

.EXAMPLE

Get-AADGroup

Returns all users registered with Azure AD

.NOTES

NAME: Get-AADGroup

#>



[cmdletbinding()]



param

(

    $GroupName,

    $id,

    [switch]$Members

)



# Defining Variables

$graphApiVersion = "v1.0"

$Group_resource = "groups"

    

    try {



        if($id){



        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"

        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value



        }

        

        elseif($GroupName -eq "" -or $GroupName -eq $null){

        

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"

        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        

        }



        else {

            

            if(!$Members){



            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"

            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

            

            }

            

            elseif($Members){

            

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"

            $Group = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

            

                if($Group){



                $GID = $Group.id



                $Group.displayName

                write-host



                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)/$GID/Members"

                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value



                }



            }

        

        }



    }



    catch {



    $ex = $_.Exception

    $errorResponse = $ex.Response.GetResponseStream()

    $reader = New-Object System.IO.StreamReader($errorResponse)

    $reader.BaseStream.Position = 0

    $reader.DiscardBufferedData()

    $responseBody = $reader.ReadToEnd();

    Write-Host "Response content:`n$responseBody" -f Red

    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

    write-host

    break



    }



}


####################################################
Function Get-CAPolicies()

{

 <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-GroupPolicyConfigurations
    #>

    [cmdletbinding()]
    
    param
    (
        $DisplayName
    )
    

	$graphApiVersion = "beta"
	#$DCP_resource = "identity/conditionalAccess/policies?'$filter=displayName eq '$displayName'"
    $DCP_resource = "identity/conditionalAccess/policies"
    
	try
	{
		
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
	    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object {($_.'displayName').contains("$DisplayName")}
		
	}
	
	catch
	{
		
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		write-host
		break
		
    }
}
####################################################

####################################################
#region Authentication

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining User Principal Name if not present

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -User $User

}

#endregion

####################################################

# Setting application AAD Group to assign Policy


#$AADGroup = "ColeTech - Allow BYOD"

$ImportPath = $ImportPath.replace('"','')

$AllowTargetGroupId = (get-AADGroup -GroupName "$AADAllowGroup").id

$ExcludeTargetGroupId = (get-AADGroup -GroupName "$AADExcludeGroup").id

#write-host $AADAllowGroup "Target Group ID = "$TargetGroupId -ForegroundColor Green

    if($AllowTargetGroupId -eq $null -or $AllowTargetGroupId -eq ""){
    
    Write-Host "AAD Group - '$AADAllowGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red

    Write-Host

    exit
        }

#write-host $AADExcludeGroup "Target Group ID = "$TargetGroupId -ForegroundColor Green

    if($ExcludeTargetGroupId -eq $null -or $ExcludeTargetGroupId -eq ""){
    
    Write-Host "AAD Group - '$AADExcludeGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red

    Write-Host

    exit
        }




# Replacing quotes for Test-Path
$ImportPath = $ImportPath.replace('"','')

if(!(Test-Path "$ImportPath")){

Write-Host "Import Path for JSON file doesn't exist..." -ForegroundColor Red
Write-Host "Script can't continue..." -ForegroundColor Red
Write-Host
break

}

####################################################

# Default state value when importing Conditional Access policy (disabled/enabledForReportingButNotEnforced/enabled)
$State = "enabledForReportingButNotEnforced"


#region import policy templates
Write-Host "Importing policy templates" -ForegroundColor Green
$Templates = Get-ChildItem -Path $ImportPath
$Policies = foreach($Item in $Templates){
    $Policy = Get-Content -Raw -Path $Item.FullName | ConvertFrom-Json
    $Policy
}
#endregion

Foreach($policy in $Policies){

    #$JSON_Data = Get-Content "$ImportPath"

    # Excluding entries that are not required - id,createdDateTime,modifiedDateTime
    #$JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id,createdDateTime,modifiedDateTime
    $JSON_Convert = $Policy | Select-Object -Property * -ExcludeProperty id,createdDateTime,modifiedDateTime
    $DuplicateCA = Get-CAPolicies -DisplayName $JSON_Convert.displayName

    #write-host $DuplicateCA
    
    If ($DuplicateCA -eq $null)

    {
        # Override state value imported from JSON file for the Conditional Access policy 
        $JSON_Convert.state = $State

        # Converting users include Group Names to Group ID
        $PermissionsincludeGroups = $JSON_Convert.conditions.users.includeGroups
        $AADGroupIncludeGroupsNames = @()
    
            foreach ($itemI in $PermissionsincludeGroups)
            {
                Write-Host "CA Policy Include Group Name =  " $itemI -ForegroundColor Green

                $AADGroup = (Get-AADGroup -GroupName $itemI)

                write-host "CA Policy Include Group ID = " $AADGroup.id

           if ($AADGroup.id -eq $null)
                    {
                            Write-Host "Groups do not exist - exiting " -ForegroundColor Red
                            exit
                    }
            
            else {
                $AADIncludeGroupName = $AADGroup.id
                $AADGroupIncludeGroupsNames += $AADIncludeGroupName
                 }       
       }

    $JSON_Convert.conditions.users.includeGroups = @($AADGroupincludeGroupsNames)
 
    # Converting users exclude Group Names to Group ID
 
    $PermissionsexcludeGroups = $JSON_Convert.conditions.users.excludeGroups

    $AADGroupexcludeGroupsNames = @()
		 
		  foreach ($itemE in $PermissionsexcludeGroups)
		    {
				Write-Host "CA Policy Exclde Group Name =  " $itemE

				$AADGroup = (Get-AADGroup -GroupName $itemE)

                write-host "CA Policy Include Group ID = " $AADGroup.id
                
              if ($AADGroup.id -eq $null)
                    {
                            Write-Host "Groups do not exist - exiting " -ForegroundColor Red
                            exit
                    }
              else {
				$AADexcludeGroupName = $AADGroup.id
                $AADGroupexcludeGroupsNames += $AADexcludeGroupName
                    }
			}
    $JSON_Convert.conditions.users.excludeGroups = @($AADGroupexcludeGroupsNames)

    $DisplayName = $JSON_Convert.displayName

    $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
            
    write-host
    write-host "Conditional Access policy '$DisplayName' Found..." -ForegroundColor Cyan
    write-host
    $JSON_Output
    Write-Host
    Write-Host "Adding Conditional Access policy '$DisplayName' (State=$State)" -ForegroundColor Yellow
    Add-ConditionalAccessPolicy -JSON $JSON_Output
        }
    
    else 
    {
        write-host "Policy already Created" $JSON_Convert.displayName -ForegroundColor Yellow
    }
}