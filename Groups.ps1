$Data = @(
    [PSCustomObject]@{GroupName="BYOD-Good-Mobile Device-Users–Enabled";GroupDesc="This group is used to apply Good configuration policies to users’ mobile devices and place the appropriate configuration controls onto the user’s mobile device"}
    [PSCustomObject]@{GroupName="BYOD-Good-PC-Users–Enabled";GroupDesc="This group is used to apply Good configuration policies to users’ PC or Mac devices and place the appropriate configuration controls onto the user’s mobiledevic"}
    [PSCustomObject]@{GroupName="BYOD-Good-Exclude Mobile Device-Users";GroupDesc="This group is used to exclude Good configuration policies being applied to users’ mobile devices. This might be because they have a corporately issued mobile device but not a laptop device."}
    [PSCustomObject]@{GroupName="BYOD-Good-Exclude PC-Users";GroupDesc="This group is used to exclude Good configuration policies being applied to users’ PC or Mac devices. This might be because they have a laptop device but not a mobile device."}
    [PSCustomObject]@{GroupName="BYOD-Better-Mobile Device-Users–Enabled ";GroupDesc="This group is used to apply Better configuration policies to users’ mobile devices and place the appropriate configuration controls onto the user’s mobile device"}
    [PSCustomObject]@{GroupName="BYOD-Better-PC-Users–Enabled";GroupDesc="This group is used to apply Better configuration policies to users’ PC or Mac devices and place the appropriate configuration controls onto the user’s mobile device"}
    [PSCustomObject]@{GroupName="BYOD-Better-Exclude Mobile Device-Users";GroupDesc="This group is used to exclude Better configuration policies being applied to users’ mobile devices. This might be because they have a corporately issued mobile device but not a laptop device."}
    [PSCustomObject]@{GroupName="BYOD-Better-Exclude PC-Users";GroupDesc="This group is used to exclude Better configuration policies being applied to users’ PC or Mac devices. This might be because they have a laptop device but not a mobile device."}
    [PSCustomObject]@{GroupName="BYOD-Best-Mobile Device-Users–Enabled ";GroupDesc="This group is used to apply Best configuration policies to users’ mobile devices and place the appropriate configuration controls onto the user’s mobile device"}
    [PSCustomObject]@{GroupName="BYOD-Best-PC-Users–Enabled";GroupDesc="This group is used to apply Best configuration policies to users’ PC or Macdevices and place the appropriate configuration controls onto the user’s mobile device"}
    [PSCustomObject]@{GroupName="BYOD-Best-Exclude Mobile Device-Users";GroupDesc="This group is used to exclude Best configuration policies being applied to users’ mobile devices. This might be because they have a corporately issued mobile device but not a laptop device."}
    [PSCustomObject]@{GroupName="BYOD-Best-Exclude PC-Users";GroupDesc="This group is used to exclude Best configuration policies being applied to users’ PC or Mac devices. This might be because they have a laptop device but not a mobile device."}
    )

$Obj = @{}

foreach ($Group in ($Data | Group GroupName)) {
    $Obj[$Group.Name] = ($Group.Group | Select -Expand GroupDesc)
}

$Obj | ConvertTo-Json | Out-File C:\Grouptest.json


