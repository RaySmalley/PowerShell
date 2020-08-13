# Clean-Up function
function Clean-Up {
    Write-Host "Cleaning up..."`n
    Remove-Item $output -Force
}

# Test for OS version
$os = Get-WmiObject win32_operatingsystem
$osVersion = [single]$os.version.subString(0,3)

# Exit if 2003/XP or older
if ($osVersion -lt 6.0) { 
    Write-Host "OS is too old, exiting..."
    Exit 101
}

# Get current MSP Backup version
$currentVersion = [System.Version](Get-Process -Name "ProcessController").ProductVersion
Write-Host "Current version is $currentVersion."`n

# Set current URL
$url = "https://cdn.cloudbackup.management/maxdownloads/mxb-windows-x86_x64.exe"

# Download
$output = $env:TEMP + "\mxb-windows-x86_x64.exe"
$Error.Clear()
Write-Host "Downloading..."`n
if (Test-Path $output) { Clean-Up }
(New-Object System.Net.WebClient).DownloadFile($url, $output)
if ($Error.count -gt 0) { Write-Host "Retrying..."`n; $Error.Clear(); (New-Object System.Net.WebClient).DownloadFile($url, $output) }
if ($Error.count -gt 0) { Write-Host "Download failed. Exiting..."; Exit 102 }
$downloadedVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$output").FileVersion
Write-Host "Version $downloadedVersion downloaded."`n

# If downloaded version is less than or equal to current version, exit
if ($downloadedVersion -eq $currentVersion) {
    Write-Host "Current version already latest version: $downloadedVersion. Exiting..."`n
    Clean-Up
    Exit 103
}

# Install
Write-Host "Installing version $downloadedVersion over $currentVersion..."`n
Start-Process -Filepath "$output" -ArgumentList '-silent' -Wait

# Check if new version installed successfully
$newVersion = [System.Version](Get-Process -Name "ProcessController").ProductVersion
if ($newVersion -gt $currentVersion) {
    Write-Host "Installation from version $currentVersion to $downloadedVersion was successful."`n
} else {
    Write-Host "Installation from version $currentVersion to $downloadedVersion failed."`nClea
}

Clean-Up