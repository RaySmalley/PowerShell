### Client ID ###

Write-Host "1 - Cuyahoga Falls"`n

$customer = Read-Host "Choose customer"

$customerID = switch ($customer)
    {
        '1' { '163' }
    }

### N-able Agent Download ###

# Download the install file to Downloads folder
$nableURL = "https://nable.415group.com/dms/FileDownload?customerID=${customerID}&softwareID=101"
$nableOutput = "$env:USERPROFILE\Downloads\${customerID}WindowsAgentSetup.exe"
Write-Host Downloading N-able Agent install file...
#(New-Object System.Net.WebClient).DownloadFile($nableURL, $nableOutput)
Invoke-WebRequest -Uri $nableURL -OutFile $nableOutput
if (Test-Path $nableOutput) { 
    Write-Host Download successful.
} else { 
    Write-Host Download failed.
}

### Webroot Download ###

$webrootKey = switch ($customerID)
    {
        '163' { 'C3D0-ENTP-AFA1-3DD9-4625' }
    }

# Download the install file to Downloads folder
$webrootURL = "https://anywhere.webrootcloudav.com/zerol/wsasme.exe"
$webrootOutput = "$env:USERPROFILE\Downloads" + "\$($webrootKey).exe" -replace '[-]',''
Write-Host Downloading Webroot install file...
(New-Object System.Net.WebClient).DownloadFile($webrootURL, $webrootOutput)
if (Test-Path $webrootOutput) { 
    Write-Host Download successful.
} else { 
    Write-Host Download failed.
}

Start $env:USERPROFILE\Downloads