# Exchange 2007
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin -ErrorAction SilentlyIgnore

# Exchange 2010
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyIgnore

# Exchange 2013 & 2016
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyIgnore

Get-MailboxStatistics -Server $env:computername | Select DisplayName, LastLogonTime | Where { $_.LastLogonTime -notlike "" } | Export-CSV C:\Temp\mailboxes.csv -NoTypeInformation