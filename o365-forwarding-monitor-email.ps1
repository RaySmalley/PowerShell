#$o365cred = Import-Clixml -Path C:\Temp\cred.xml
#$o365cred2 = Import-Clixml -Path C:\Temp\cred2.xml
$o365cred = Get-Credential

$o365session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $o365cred -Authentication Basic -AllowRedirection

Import-PSSession $o365session

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

$mailboxes = Get-Mailbox -ResultSize Unlimited
$results = @()
$deletes = @()

ForEach ($mailbox in $mailboxes) {
    $rules = Get-InboxRule -Mailbox $mailbox.PrimarySmtpAddress
    $results += $rules | where { ( $_.forwardAsAttachmentTo ) -or ( $_.forwardTo ) -or ( $_.redirectTo ) } | Select-Object MailboxOwnerID,Name,Enabled,ForwardTo,RedirectTo
    $deletes += $rules | where { $_.DeleteMessage } | select-object MailboxOwnerID,Description,Name,Enabled
}

If ( $deletes ) { $deletes = $deletes | ConvertTo-HTML -Head $style }

$ToAddress = 'rsmalley@415group.com'
$FromAddress = Read-Host 'Enter from address: '
$SMTPServer = 'smtp.office365.com'
$SmtpPort = '587'

If ( $results -eq $NULL ) {
$results = 'No Mailbox Rules found with forwarding.'
} Else {
$results = $results | ConvertTo-HTML -Head $style }

$mailparam = @{
To = $ToAddress
From = $FromAddress
Subject = 'Office 365 Mailbox Rules With Forwarding Or Deletions'
Body = $results,"<br />",$deletes | out-string
BodyAsHTML = $true
SmtpServer = $SMTPServer
Port = $SmtpPort
Credential = $o365cred2
}

Send-MailMessage @mailparam -UseSSL

Remove-PSSession $o365session