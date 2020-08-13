Import-Module MSOnline

# Connect to Office 365
$host.ui.RawUI.WindowTitle = "Enter creds."
Write-Host "Please enter Office 365 admin credentials."
Write-Host " "
$Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $credentials -Authentication Basic -AllowRedirection
Write-Host " "
$host.ui.RawUI.WindowTitle = "Connecting..."
Write-Host "Getting the Exchange Online cmdlets..."
Write-Host " "
Import-PSSession $Session
Write-Host " "

$domains = Get-AcceptedDomain
$host.ui.RawUI.WindowTitle = ($domains).Name
$mailboxes = Get-Mailbox -ResultSize Unlimited
$externalTransportRuleName = "Block Inbox Rules that Forward Email Externally"
$rejectMessageText = "To improve security, auto-forwarding mail to external addresses has been disabled. Please contact your Office 365 Administrator if you would like to set up an exception."
$externalForwardRule = Get-TransportRule | Where-Object {$_.Identity -Contains $externalTransportRuleName}

# Remove old transport rule if exists
$oldTransportRule = (Get-TransportRule | Where-Object {$_.Identity -Contains "Block Inbox Rules that Forward Mail Externally"}).Name
if ($oldTransportRule) {
    Remove-TransportRule $oldTransportRule -Confirm:$false
    Write-Host "Removed old transport rule: ""$oldTransportRule""."
    Write-Host " "
}

# Exit if transport rule already exists
if ($externalForwardRule) {
    $host.ui.RawUI.WindowTitle = "Rule exists!"
    Write-Host " "
    Write-Host """$externalTransportRuleName"" transport rule already exists. Nothing has been changed."
    Read-Host -Prompt "Press Enter to exit"
    Exit
}

# Check each account for existing auto-forwarding inbox rules
foreach ($mailbox in $mailboxes) {
 
    $forwardingRules = $null
    Write-Host "Checking rules for $($mailbox.displayname) - $($mailbox.primarysmtpaddress)" -foregroundColor Green
    $rules = Get-InboxRule -Mailbox $mailbox.primarysmtpaddress
     
    $forwardingRules = $rules | Where-Object {$_.forwardTo -or $_.forwardAsAttachmentTo -or $_.redirectTo}
 
    foreach ($rule in $forwardingRules) {
        $recipients = @()
        $recipients = $rule.ForwardTo | Where-Object {$_ -Match "SMTP"}
        $recipients += $rule.ForwardAsAttachmentTo | Where-Object {$_ -Match "SMTP"}
        $recipients += $rule.redirectTo | Where-Object {$_ -Match "SMTP"}
     
        $externalRecipients = @()
 
        foreach ($recipient in $recipients) {
            $email = ($recipient -Split "SMTP:")[1].Trim("]")
            $domain = ($email -Split "@")[1]
 
            if ($domains.DomainName -NotContains $domain) {
                $externalRecipients += $email
            }    
        }
 
        if ($externalRecipients) {
            $extRecString = $externalRecipients -Join ", "
            Write-Host "$($rule.Name) forwards to $extRecString" -ForegroundColor Yellow
 
            $ruleHash = $null
            $ruleHash = [ordered]@{
                PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
                DisplayName        = $mailbox.DisplayName
                RuleId             = $rule.Identity
                RuleName           = $rule.Name
                RuleDescription    = $rule.Description
                ExternalRecipients = $extRecString
            }
            $ruleObject = New-Object PSObject -Property $ruleHash
            $ruleObject | Export-Csv C:\temp\externalrules-$domain.csv -NoTypeInformation -Append
        }
    }
}

# Exit if auto-forwarding is already enabled on a user's account
# Create blocking transport rule if not
if ($externalRecipients) {
    $host.ui.RawUI.WindowTitle = "Forwarding exists."
    Write-Host " "
    Write-Host "There are currently user(s) utilizing external forwarding. Transport rule will not be created."
} else {
    Write-Host " "
    Write-Host "Creating ""$externalTransportRuleName"" transport rule..."
    New-TransportRule -name "$externalTransportRuleName" -Priority 0 -SentToScope NotInOrganization -FromScope InOrganization -MessageTypeMatches AutoForward -RejectMessageEnhancedStatusCode 5.7.1 -RejectMessageReasonText $rejectMessageText
}

Write-Host " "
Write-Host Done!
$host.ui.RawUI.WindowTitle = "Done! $(($domains).Name)"

Remove-PSSession $Session

Write-Host " "
Read-Host -Prompt "Press Enter to exit"