# BYOD-UK-Blueprint-Auto

This Github is for Automating the BYOD-UK-Blueprint advice provided here: https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4zeV7

A large number of the scripts are based on the powershell scripts created by Dave Falkus which can be found here: https://github.com/davefalkus/powershell-intune-samples

# Implementation Guide #

THe following provides details on what each script does:

## BYOD-UK-BP-MasterScript.ps1 ##

Triggers the running of all other scripts

## AADGroups-Create.ps1 ##

Creates the following Groups:

BYOD-Good-Mobile Device-Users-Enabled
BYOD-Good-PC-Users-Enabled
BYOD-Good-Exclude Mobile Device-Users
BYOD-Good-Exclude PC-Users
BYOD-Better-Mobile Device-Users-Enabled
BYOD-Better-PC-Users-Enabled
BYOD-Better-Exclude-Mobile Device-Users
BYOD-Better-Exclude PC-Users
BYOD-Best-Mobile Device-Users-Enabled
BYOD-Best-PC-Users-Enabled
BYOD-Best-Exclude Mobile Device-Users
BYOD-Best-Exclude PC-Users

## AppRegistration-Create.ps1 ##

Creates an AppRegistration called CA Policy PowerShell Tool with the correct permissions to export/import of Conditional Access Policies

## CA-Policies-Import.ps1 ##

Imports Conditional Access policies from the "JSON\CA JSON folder" into tenant with the correct permissions in Readonly mode

## MAM-Policies-Import.ps1 ##

Imports App Protectin Policies from teh "JSON\MAM" Folder into tenant -  Work in progress








