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
        $User
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
    
        Connect-AzureAD -AccountId $user
    
    }
    
####################################################
    
    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"

    Set-AADAuth -user $user
    
 ####################################################
    
    


write-host "Adding required AAD Groups"

 . $ScriptDir/AADGroups-Create.ps1

write-host "Adding App Registrtion for Conditional Access Policies"

. $ScriptDir/AppRegistration-Create.ps1

Start-Sleep -s 5

write-host "Adding Conditional Access Policies - Report Only"

. $ScriptDir/CA-Policies-Import.ps1 -user $user -folder "CA JSON"

$msg = 'Do you have WVD enabled [Y/N]'
     $response = Read-Host -Prompt $msg
    if ($response -eq 'y') {
        . $ScriptDir/CA-Policies-Import.ps1 -user $user -folder "CA WVD JSON"
    }
    else {
        write-host "The script will continue without the WVD Conditional Access Policies. Please re-run the script once WVD is enabled to apply the WVD Conditional Access Policies." -ForegroundColor red
    }

Start-Sleep -s 5

write-host "Adding App Protection Policies"

. $ScriptDir/MAM-Policies-Import.ps1

Start-Sleep -s 5

write-host "Adding App Configuration Policies"

. $ScriptDir/AC-Policies-Import.ps1

Start-Sleep -s 5

write-host "Adding Device Enrollement Restrictions"

. $ScriptDir/DER-Import.ps1



