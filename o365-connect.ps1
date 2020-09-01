$O365Cred = Get-Credential
#$O365Cred = Import-Clixml -Path C:\Temp\cred.xml
$O365Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365Cred -Authentication Basic -AllowRedirection
Import-PSSession $O365Session -DisableNameChecking

# Enter this command when you are done to end session:
# Remove-PSSession $O365Session