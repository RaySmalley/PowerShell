$MyDomain = "domain.com"
$MyHostname = "$env:COMPUTERNAME"
$GoDaddyAPIKey = "key:secret"

$MyIP = Invoke-RestMethod -Uri "https://api.ipify.org"
$DNSdata = Invoke-RestMethod "https://api.godaddy.com/v1/domains/$($MyDomain)/records/A/$($MyHostname)" -Headers @{ Authorization = "sso-key $($GoDaddyAPIKey)" }
$GoDaddyIP = $DNSdata.data

Write-Output "$(Get-Date -Format 'u') - Current External IP is $($MyIP), GoDaddy DNS IP is $($GoDaddyIP)"

If ( $GoDaddyIP -ne $MyIP) {
    Write-Output "IP has changed. Updating on GoDaddy..."
    Invoke-RestMethod -Method PUT -Uri "https://api.godaddy.com/v1/domains/$($MyDomain)/records/A/$($MyHostname)" -Headers @{ Authorization = "sso-key $($GoDaddyAPIKey)" } -ContentType "application/json" -Body "[{`"data`": `"$($MyIP)`"}]";
}