<#
Script for downloading and installing Webroot(TM) Endpoint Security
Downloads a current version of the installer
Command line paramater must equal the install key i.e. SAA9-XXXX-XXXX-XXXX-52E6

Exits if no command line paramater is provided
If WRSA.exe is a running process - script exits as it is assumed that WSAB is already installed

Requires admin rights
#>

# 
if ($args) {
    $key = $($args[0])
} else {
    $key = switch ($env:USERDOMAIN)
    {
        'KNOCHCORP' { '5E08-ENTP-1F12-6FF0-409D' }
        'RSMALLEY-10PC' { 'XXXX-XXXX-XXXX-XXXX' }
    }
}

# Exit script if Webroot is running (and therefore already installed)
if (Get-Process WRSA -ErrorAction SilentlyContinue) {
    Write-Host Webroot is already installed and running. Exiting script...
    Exit
}

if (! $key) {
    Write-Host A key was not supplied and could not be found in the list. Exiting...
    Exit
}

# Download install file to current TEMP path
$url = "https://anywhere.webrootcloudav.com/zerol/wsasme.exe"
$output = $env:TEMP + "\$key.exe" -replace '[-]',''
Write-Host Downloading Webroot install file...
(New-Object System.Net.WebClient).DownloadFile($url, $output)
if (Test-Path $output) { 
    Write-Host Download successful.
} else { 
    Write-Host Download failed. Exiting...
    Exit
}

# Install Webroot in background
Write-Host Installing Webroot in background...
Start-Process $output -Wait
if (Get-Process WRSA -ErrorAction SilentlyContinue) {
    Write-Host Installation successful!
} else {
    Write-Host Installation failed.
}
