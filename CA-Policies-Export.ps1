function Get-AuthToken
{
	
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
		[Parameter(Mandatory = $true)]
		$User
	)
	
	$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
	
	$tenant = $userUpn.Host
	
	Write-Host "Checking for AzureAD module..."
	
	$AadModule = Get-Module -Name "AzureAD" -ListAvailable
	
	if ($AadModule -eq $null)
	{
		
		Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
		$AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
		
	}
	
	if ($AadModule -eq $null)
	{
		write-host
		write-host "AzureAD Powershell module not installed..." -f Red
		write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
		write-host "Script can't continue..." -f Red
		write-host
		exit
	}
	
	# Getting path to ActiveDirectory Assemblies
	# If the module count is greater than 1 find the latest version
	
	if ($AadModule.count -gt 1)
	{
		
		$Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
		
		$aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }
		
		# Checking if there are multiple versions of the same module found
		
		if ($AadModule.count -gt 1)
		{
			
			$aadModule = $AadModule | Select-Object -Unique
			
		}
		
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
		
	}
	else
	{
		
		$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
		$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
		
	}
	
	[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
	
	[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null


	
	$CAAppReg = get-AzureADApplication -filter "DisplayName eq 'CA Policy PowerShell Tool'"

    if ($CAAppReg -eq $null)
        { 
           Write-Host "Run AppRegistration scipt" -ForegroundColor Red
           
        }
    else 
        {
            $clientId = $CAAppReg.appid

        }



	#$clientId = "5326eec5-1498-4340-9e90-d37a981de794"
	
	$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
	
	$resourceAppIdURI = "https://graph.microsoft.com"
	
	$authority = "https://login.microsoftonline.com/$Tenant"
	
	try
	{
		
		$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
		
		# https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
		# Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
		
		$platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
		
		$userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
		
		$authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result
		
		# If the accesstoken is valid then create the authentication header
		
		if ($authResult.AccessToken)
		{
			
			# Creating header for Authorization token
			
			$authHeader = @{
				'Content-Type'  = 'application/json'
				'Authorization' = "Bearer " + $authResult.AccessToken
				'ExpiresOn'	    = $authResult.ExpiresOn
			}
			
			return $authHeader
			
		}
		
		else
		{
			
			Write-Host
			Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
			Write-Host
			break
			
		}
		
	}
	
	catch
	{
		
		write-host $_.Exception.Message -f Red
		write-host $_.Exception.ItemName -f Red
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

$graphApiVersion = "beta"
$DCP_resource = "identity/conditionalAccess/policies"
	
	try
	{
		
		$uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
		(Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
		
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
if ($global:authToken)
{
	
	# Setting DateTime to Universal time to work in all timezones
	$DateTime = (Get-Date).ToUniversalTime()
	
	# If the authToken exists checking when it expires
	$TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
	
	if ($TokenExpires -le 0)
	{
		
		write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
		write-host
		
		# Defining User Principal Name if not present
		
		if ($User -eq $null -or $User -eq "")
		{
			
			$User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
			Write-Host
			
		}
		
		$global:authToken = Get-AuthToken -User $User
		
	}
}

# Authentication doesn't exist, calling Get-AuthToken function

else
{
	
	if ($User -eq $null -or $User -eq "")
	{
		
		$User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
		Write-Host
		
	}
	
	# Getting the authorization token
	$global:authToken = Get-AuthToken -User $User
	
}

#endregion

####################################################

####################################################

Function Export-JSONData(){

    <#
    .SYNOPSIS
    This function is used to export JSON data returned from Graph
    .DESCRIPTION
    This function is used to export JSON data returned from Graph
    .EXAMPLE
    Export-JSONData -JSON $JSON
    Export the JSON inputted on the function
    .NOTES
    NAME: Export-JSONData
    #>
    
    param (
    
    $JSON,
    $ExportPath
    
    )
    
        try {
    
            if($JSON -eq "" -or $JSON -eq $null){
    
            write-host "No JSON specified, please specify valid JSON..." -f Red
    
            }
    
            elseif(!$ExportPath){
    
            write-host "No export path parameter set, please provide a path to export the file" -f Red
    
            }
    
            elseif(!(Test-Path $ExportPath)){
    
            write-host "$ExportPath doesn't exist, can't export JSON Data" -f Red
    
            }
    
            else {
    
            $JSON1 = ConvertTo-Json $JSON -Depth 5
    
            $JSON_Convert = $JSON1 | ConvertFrom-Json
    
            $displayName = $JSON_Convert.displayName
    
            # Updating display name to follow file naming conventions - https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
            $DisplayName = $DisplayName -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
    
            $Properties = ($JSON_Convert | Get-Member | ? { $_.MemberType -eq "NoteProperty" }).Name
    
                #$FileName_CSV = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".csv"
                $FileName_JSON = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json"
    
                $Object = New-Object System.Object
    
                    foreach($Property in $Properties){
    
                    $Object | Add-Member -MemberType NoteProperty -Name $Property -Value $JSON_Convert.$Property
    
                    }
    
                write-host "Export Path:" "$ExportPath"
    
                #$Object | Export-Csv -LiteralPath "$ExportPath\$FileName_CSV" -Delimiter "," -NoTypeInformation -Append
                $JSON1 | Set-Content -LiteralPath "$ExportPath\$FileName_JSON"
                #write-host "CSV created in $ExportPath\$FileName_CSV..." -f cyan
                write-host "JSON created in $ExportPath\$FileName_JSON..." -f cyan
                
            }
    
        }
    
        catch {
    
        $_.Exception
    
        }
    
    }
    
	####################################################
	

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

####################################################

$CAPolicies = Get-CAPolicies

foreach ($CAP in $CAPolicies)

{
	# Export-JSONData -JSON $CAP -ExportPath $ExportPath
	
	$FileName = $($CAP.displayName) -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
	 New-Item "$ExportPath\$($FileName).json" -ItemType File -Force
   

	 # Converting users include groups from IDs to Group Names

	 Write-Host "this is Include" $CAP.conditions.users.includeGroups

	 $PermissionsincludeGroups = $CAP.conditions.users.includeGroups

	 	 $AADGroupIncludeGroupsNames = @()
		 
		  foreach ($itemI in $PermissionsincludeGroups)
		    {
				Write-Host "each item include " $itemI

				$AADGroup = (Get-AADGroup -id $itemI)

				write-host $AADGroup.displayname

				$AADIncludeGroupName = $AADGroup.displayName

				$AADGroupIncludeGroupsNames += $AADIncludeGroupName
			}

	 $CAP.conditions.users.includeGroups = @($AADGroupincludeGroupsNames)

	 # Converting users exclude groups from IDs to Group Names
	 
	 Write-Host "this is Exclude" $CAP.conditions.users.excludeGroups

	 $PermissionsexcludeGroups = $CAP.conditions.users.excludeGroups

	 	 $AADGroupexcludeGroupsNames = @()
		 
		  foreach ($itemE in $PermissionsexcludeGroups)
		    {
				Write-Host "each item Exclude " $itemE

				$AADGroup = (Get-AADGroup -id $itemE)

				write-host $AADGroup.displayname

				$AADexcludeGroupName = $AADGroup.displayName

				$AADGroupexcludeGroupsNames += $AADexcludeGroupName
			}

	 $CAP.conditions.users.excludeGroups = @($AADGroupexcludeGroupsNames)

	 $JSON_DATA = $CAP | ConvertTo-Json -depth 5

	 $JSON_Data | Out-File -FilePath "$ExportPath\$($FileName).json" -Append -Encoding ascii


}

