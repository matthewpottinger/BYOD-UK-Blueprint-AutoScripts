# BYOD-UK-Blueprint-Auto

This GitHub is for Automating the BYOD-UK-Blueprint advice provided here: https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4zeV7

A large number of the scripts are based on the PowerShell scripts created by Dave Falkus which can be found here: https://github.com/davefalkus/powershell-intune-samples

***Please note this code is still under development and is not in its final state***

# Script information #

The following provides details on what each script does

## BYOD-UK-BP-MasterScript.ps1 ##

Triggers the running of all other scripts

## AADGroups-Create.ps1 ##

Creates the following Groups:

- BYOD-Good-Mobile Device-Users-Enabled
- BYOD-Good-PC-Users-Enabled
- BYOD-Good-Exclude Mobile Device-Users
- BYOD-Good-Exclude PC-Users
- BYOD-Better-Mobile Device-Users-Enabled
- BYOD-Better-PC-Users-Enabled
- BYOD-Better-Exclude-Mobile Device-Users
- BYOD-Better-Exclude PC-Users
- BYOD-Best-Mobile Device-Users-Enabled
- BYOD-Best-PC-Users-Enabled
- BYOD-Best-Exclude Mobile Device-Users
- BYOD-Best-Exclude PC-Users

## AppRegistration-Create.ps1 ##

Creates an AppRegistration called **BYOD UK BP PowerShell Tool** with the following permissions:

 - Group.Read.All (Groups)
 - Policy.Read.All (CA)
 - Application.Read.All (CA)
 - Policy.ReadWrite.ConditionalAccess (CA)
 - DeviceManagementApps.ReadWrite.All (MAM)
 - DeviceManagementServiceConfig.ReadWrite.All (DER)

to export/import all required Policies

## CA-Policies-Import.ps1 ##

Imports Conditional Access policies from the **JSON\CA JSON** folder into tenant with the correct permissions in Report Only Mode

## MAM-Policies-Import.ps1 ##

Imports App protection policies from the **JSON\MAM** Folder into tenant with the correct permissions


## AC-Policies-Import.ps1 ##

Imports App configuration Policies from the **JSON\ACP** Folder into tenant with the permissions

## DER-Import.ps1 ##

Imports Device Enrollement Restrictions into the tenant.  Currently will be lowest priority after the Default policy


# Implementation Guide #

Work in Progress









