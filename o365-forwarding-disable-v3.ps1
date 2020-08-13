if (-Not (Get-Module -Name MSOnline -ListAvailable)) { Install-Module -Name MSOnline -Confirm }

if (-Not (Get-Module -Name MSOnline)) { Import-Module -Name MSOnline }

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

Enable-OrganizationCustomization -Confirm:$false -ErrorAction SilentlyContinue

$domains = Get-AcceptedDomain
$host.ui.RawUI.WindowTitle = ($domains).Name
$mailboxes = Get-Mailbox -ResultSize Unlimited

$oldTransportRule = (Get-TransportRule | Where-Object {$_.Identity -Match "Block Inbox Rules that Forward"}).Name
if ($oldTransportRule) {
    Remove-TransportRule $oldTransportRule -Confirm:$false
    Write-Host "Removed old transport rule: ""$oldTransportRule""."
    Write-Host " "
}

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

if ($externalRecipients) {
    $host.ui.RawUI.WindowTitle = "Forwarding exists."
    Write-Host " "
    Write-Host "There are currently user(s) utilizing external forwarding. Rule will not be created."
} else {
    Write-Host " "
    Write-Host "Disabling Auto-Forwarding features in OWA..."
    New-ManagementRole -Parent MyBaseOptions -Name DenyForwarding
    Set-ManagementRoleEntry DenyForwarding\New-InboxRule -RemoveParameter -Parameters ForwardTo, RedirectTo, ForwardAsAttachmentTo
    New-RoleAssignmentPolicy -Name DenyForwardingRoleAssignmentPolicy -Roles DenyForwarding, MyContactInformation, MyRetentionPolicies, MyMailSubscriptions, MyTextMessaging, MyVoiceMail, MyDistributionGroupMembership, MyDistributionGroups, MyProfileInformation

}

Write-Host " "
Write-Host Done!
$host.ui.RawUI.WindowTitle = "Done! $(($domains).Name)"

Remove-PSSession $Session

Write-Host " "
Read-Host -Prompt "Press Enter to exit"