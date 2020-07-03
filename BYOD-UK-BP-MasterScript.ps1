# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

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
    
    


write-host "Adding required AAD Groups"

. $ScriptDir/AADGroups-Create.ps1

write-host "Adding App Registrtion for Conditional Access Policies"

. $ScriptDir/AppRegistration-Create.ps1

write-host "Adding Conditional Access Policies - Report Only"

. $ScriptDir/CA-Policies-Import.ps1

write-host "Adding App Protection Policies - Unassigned"

. $ScriptDir/MAM-Policies-Import

