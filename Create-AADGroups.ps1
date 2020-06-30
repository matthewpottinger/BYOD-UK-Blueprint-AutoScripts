####################################################


####################################################

$GroupsJSON = "C:\Users\mapottin\Documents\GitHub\BYOD-UK-Blueprint-Auto\Groups.json"

Function Set-AADAuth {
<#
.SYNOPSIS
This function is used to authenticate with the Azure AD interface
.DESCRIPTION
The function authenticate with the Azure AD Interface with the tenant name
.EXAMPLE
Set-AADAuth
Authenticates you with the Azure AD interface
.NOTES
NAME: Set-AADAuth
#>

[cmdletbinding()]

param
(
    #[Parameter(Mandatory=$true)]
    #$User
)

Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Attempting module install now" -f Red
        Install-Module -Name AzureAD -AllowClobber -Force
        #write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        #write-host "Script can't continue..." -f Red
        write-host
        #exit
    }

    Connect-AzureAD

}

####################################################

Set-AADAuth

####################################################


# Find JSON
$JSONFiles = Get-Childitem –Path $GroupsJSON


If ($JSONFiles.Count -eq 0){
    Write-Host
    Write-Host "Error - no JSON file detected in current path: $GroupsJSON" -f Red
    Write-Host
}
Else {
    $JSONFileName = $JSONFiles.FullName
    Write-Host
    Write-Host "Using JSON file: $JSONFileName"
    Write-Host

    $AADGroups = Get-Content -Path $JSONFileName | ConvertFrom-Json

  
    }


ForEach ($Group in $AADGroups) 
    
                {

                #Write-Host "Group Name = " $Group.GroupName "and the Desc" $group.desc
                
                If (Get-AzureADGroup -SearchString $Group.GroupName) {
                        Write-Host
                        Write-Host "AAD group" $Group.GroupName "already exists!" -f Yellow
                        Write-Host
                        }
                Else {
                        $MailNickName = $group.GroupName -replace "\s", '-'
                                              
                           try
                            {
                                New-AzureADGroup -DisplayName $Group.GroupName -Description $Group.desc -MailEnabled $false -SecurityEnabled $true -MailNickName $MailNickName"-Group"
                            
                            }
                           catch
                            {
                              Write-Host
                              Write-Host "Error creating AAD group" $Group.GroupName -f Red
                              Write-Host
                            }

                            } 
                }