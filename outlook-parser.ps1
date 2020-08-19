Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$MAPI = $Outlook.GetNameSpace("MAPI")
$OlFolderInbox = 6
$Inbox = $MAPI.GetDefaultFolder($OlFolderInbox)

$Inbox.items | Where-Object { $_.body -Match "User name: " } | Select-Object SenderEmailAddress,to,subject | Format-Table -AutoSize

#$RegEx = [RegEx]'(?sm)User name:\s+(?<Username>.*?)$.*?password:\s+(?<Password>.*?)$.'

#foreach ($item in $Inbox.items) {
#    if ($item.body -match "password:") {
#         $Matches[0]
#    }
#