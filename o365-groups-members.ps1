Import-Module MSOnline
$O365Cred = Get-Credential
$O365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365Cred -Authentication Basic -AllowRedirection 
Import-PSSession $O365Session -DisableNameChecking
Connect-MsolService -Credential $O365Cred

$OutputFile="$env:USERPROFILE\Desktop\groups-n-members.csv" 
 
$arrDMembers = @{}   
Out-File -FilePath $OutputFile -InputObject "Group DisplayName, Group Email, Member DisplayName, Member Email" -Encoding UTF8    
$objGroups = Get-msolgroup -All | Sort-object objectid   
Foreach ($objGroup in $objGroups)    
{        
   
 write-host "Processing $($objGroup.DisplayName)..."  
$objGMembers = Get-MsolGroupMember -groupobjectid $($objGroup.objectid)    
  
 write-host "Found $($objGMembers.Count) members..."    
  
 $name = $_.objectid  
$displayname = $_.displayname  
$email = $_.proxyaddresses  
Foreach ($objMember in $objGMembers)    
    {    
   
Out-File -FilePath $OutputFile -InputObject "$($objGroup.DisplayName),$($objGroup.proxyaddresses),$($objMember.DisplayName),$($objMember.EmailAddress)" -Encoding UTF8 -append    
          
write-host "`t$($objGroup.DisplayName),$($objGroup.proxyaddresses),$($objMember.DisplayName),$($objMember.EmailAddress)"   
    }  
   
}

Remove-PSSession $O365session