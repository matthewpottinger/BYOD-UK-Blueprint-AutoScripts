
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

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

$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

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

Function Get-DeviceEnrollmentConfigurations(){
    
<#
.SYNOPSIS
This function is used to get Deivce Enrollment Configurations from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets Device Enrollment Configurations
.EXAMPLE
Get-DeviceEnrollmentConfigurations
Returns Device Enrollment Configurations configured in Intune
.NOTES
NAME: Get-DeviceEnrollmentConfigurations
#>
    
    [cmdletbinding()]
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceEnrollmentConfigurations?`$expand=assignments"
        
        try {
            
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
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


$ExportPath = Read-Host -Prompt "Please specify a path to export the policy data to e.g. C:\IntuneOutput"

# If the directory path doesn't exist prompt user to create the directory
$ExportPath = $ExportPath.replace('"', '')

if (!(Test-Path "$ExportPath"))
{
	
	Write-Host
	Write-Host "Path '$ExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow
	
	$Confirm = read-host
	
	if ($Confirm -eq "y" -or $Confirm -eq "Y")
	{
		
		new-item -ItemType Directory -Path "$ExportPath" | Out-Null
		Write-Host
		
	}
	
	else
	{
		
		Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
		Write-Host
		break
		
	}
	
}

$DeviceEnrollmentConfigurations = Get-DeviceEnrollmentConfigurations
$DeviceEnrollmentConfigurations = $DeviceEnrollmentConfigurations | Where-Object { ($_.id).contains("_PlatformRestrictions") }


foreach ($DEC in $DeviceEnrollmentConfigurations)

{
	# Export-JSONData -JSON $CAP -ExportPath $ExportPath
	
	$FileName = $($DEC.displayName) -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
	New-Item "$ExportPath\$($FileName).json" -ItemType File -Force

    $DEC.assignments.target | 

    ForEach-Object {
     
       $GroupID = $_.GroupId

       write-host "GroupID" $GroupID

       $AADGroup = (Get-AADGroup -id $GroupId)

       
       write-host "GroupName" $AADGroup.DisplayName
       $_.GroupID = $AADGroup.DisplayName
    
    }

    $DEC.assignments.target
    
    $JSON_DATA = $DEC | ConvertTo-Json -depth 10

    $JSON_Data | Out-File -FilePath "$ExportPath\$($FileName).json" -Append -Encoding ascii


}