<#
Script for downloading and installing Webroot(TM) Endpoint Security
Downloads a current version of the installer
Command line paramater must equal the install key i.e. SAA9-XXXX-XXXX-XXXX-52E6

Exits if no command line paramater is provided
If WRSA.exe is a running process - script exits as it is assumed that WSAB is already installed

Requires admin rights
#>

# Exit if no command line parameter provided
if ($args.count -ne 1) {
    Write-Host The install key must be supplied as the one and only parameter. Exiting...
    Exit
}

# Exit script if Webroot is running (and therefore already installed)
#if (Get-Process WRSA -ErrorAction SilentlyContinue) {
#    Write-Host Webroot is already installed and running. Exiting script...
#    Exit
#}

# Download the install file to current TEMP path
$url = "https://anywhere.webrootcloudav.com/zerol/wsasme.exe"
$output = $env:TEMP + "\$($args[0]).exe" -replace '[-]',''
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
