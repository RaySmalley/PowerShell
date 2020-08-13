Write-Host "Download the cert from the CA, extract if necessary, and place in C:\Temp\"

$Domain = Read-Host -Prompt "Enter the domain for the SSL cert (e.g. mail.domain.com): "

$oldThumbprint = Get-ExchangeCertificate | where {$_.Status -eq "Valid" -and $_.IsSelfSigned -eq $false -and $_.Subject -match "$Domain"} | Select -ExpandProperty Thumbprint

#Get-ExchangeCertificate -Thumbprint $Thumbprint | New-ExchangeCertificate -GenerateRequest

Remove-ExchangeCertificate -Thumbprint $oldThumbprint

Import-ExchangeCertificate -FileData ([Byte[]](Get-Content -Encoding Byte -Path "C:\Temp\*.crt" -ReadCount 0))

$newThumbprint = Get-ExchangeCertificate | where {$_.Status -eq "Valid" -and $_.IsSelfSigned -eq $false -and $_.Subject -match "$Domain"} | Select -ExpandProperty Thumbprint

Enable-ExchangeCertificate -Thumbprint $newThumbprint -Services POP,IMAP,SMTP,IIS -Force