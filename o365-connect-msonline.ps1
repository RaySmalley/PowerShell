# If you get errors run: Install-Module MSOnline -Force

Import-Module MSOnline
$O365Cred = Get-Credential
$O365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365Cred -Authentication Basic -AllowRedirection 
Import-PSSession $O365Session -DisableNameChecking
Connect-MsolService -Credential $O365Cred