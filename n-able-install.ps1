$customerID = Read-Host "Enter Customer ID: "

$url = "https://nable.415group.com/dms/FileDownload?customerID=" + $customerID + "&softwareID=101"
$output = $env:TEMP + "\" + $customerID + "WindowsAgentSetup.exe"
$startTime = Get-Date

(New-Object System.Net.WebClient).DownloadFile($url, $output)

Invoke-Expression "& '$output' /quiet "