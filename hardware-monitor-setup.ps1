# Exit if not Dell
if (-Not ((Get-WmiObject -Class:Win32_ComputerSystem).Manufacturer -like "*Dell*")) { 
    Write-Host "System is not a Dell, exiting..."
    Exit 101
}

# Set current OpenManage versions and URLs
$latestVersion = "9.4.0"
$x86URL = "https://downloads.dell.com/FOLDER04242160M/1/OM-SrvAdmin-Dell-Web-WIN-8.5.0-2372_A00.exe"
$oldURL = "https://downloads.dell.com/FOLDER04242232M/1/OM-SrvAdmin-Dell-Web-WINX64-8.5.0-2372_A00.exe"
$latestURL = "https://downloads.dell.com/FOLDER06019899M/1/OM-SrvAdmin-Dell-Web-WINX64-9.4.0-3787_A00.exe"

# Test for OS version
$os = Get-WmiObject win32_operatingsystem
$osVersion = [single]$os.version.subString(0,3)

# Check if SNMP is already set up
Write-Host "Checking if SNMP already set up..."`n
if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" -ErrorAction SilentlyContinue).public -ne 4) {

    # Install SNMP Feature
    Write-Host "Installing SNMP Feature..."`n
    Import-Module ServerManager
    if ($osVersion -lt 6.2) {Add-WindowsFeature SNMP-Service -IncludeAllSubFeature}
    if ($osVersion -ge 6.2) {Add-WindowsFeature SNMP-Service -IncludeAllSubFeature -IncludeManagementTools}

    # Configure SNMP
    Write-Host "Configuring SNMP..."`n
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" -Name "public" -Value "4" -PropertyType DWORD -Force | Out-Null
} else { Write-Host "SNMP already set up."`n }

# Check if latest version of OpenManange is installed. Download and install it if not.
Write-Host "Checking if latest version of OpenMange is installed..."
$omVersion = [System.Version](Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object { $_.DisplayName -like "*OpenManage*" }).DisplayVersion
if (-Not $omVersion) { $omVersion = [System.Version](Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object { $_.DisplayName -like "*OpenManage*" }).DisplayVersion }
$output = $env:TEMP + "\OpenManage.exe"
Write-Host ""

if ($os.osarchitecture -match "86") {
    if ($omVersion -lt "8.5.0") {
        if ($omVersion -gt "1.0.0") { Write-Host "OpenManage version $omVersion installed. Newer version available."`n } else { Write-Host "OpenManage not installed."`n }
        $url = $x86URL
    } else { Write-Host "OpenMange version current."`n }
} else {
    if ($osVersion -lt 6.2) {
        if ($omVersion -lt "8.5.0") {
            if ($omVersion -gt "1.0.0") { Write-Host "OpenManage version $omVersion installed. Newer version available."`n } else { Write-Host "OpenManage not installed."`n }
            $url = $oldURL
        } else { Write-Host "OpenMange version current."`n }
    }
    if ($osVersion -ge 6.2) {
        if ($omVersion -lt "$latestVersion") {
            if ($omVersion -gt "1.0.0") { Write-Host "OpenManage version $omVersion installed. Newer version available."`n } else { Write-Host "OpenManage not installed."`n }
            $url = $latestURL
        } else { Write-Host "OpenMange version current."`n }
    }
}

# If necessary, download, extract, and install OpenManage
if ($url) {
    # Download
    $Error.Clear()
    Write-Host "Downloading OpenManage..."`n
    if (!(Test-Path $output)) { (New-Object System.Net.WebClient).DownloadFile($url, $output) }
    if ($Error.count -gt 0) { Write-Host "Retrying..."`n; $Error.Clear(); (New-Object System.Net.WebClient).DownloadFile($url, $output) }
    if ($Error.count -gt 0) { Write-Host "Download failed. Exiting..."; Exit 102 }

    # Extract
    Write-Host "Extracting files..."`n
    Start-Process -Filepath "$output" -ArgumentList "/auto" -Wait

    # Install
    Write-Host "Installing OpenManage..."`n
    if ($os.osarchitecture -match "86") {
        Start-Process -FilePath msiexec -ArgumentList /i,"C:\OpenManage\windows\SystemsManagement\SysMgmt.msi", /quiet -Wait
    } else {
        Start-Process -FilePath msiexec -ArgumentList /i,"C:\OpenManage\windows\SystemsManagementx64\SysMgmtx64.msi", /quiet -Wait
    }

    # Clean up
    Write-Host "Cleaning up..."`n
    Remove-Item $output -Force
    Remove-Item "C:\OpenManage" -Recurse -Force
}

# Fix for Non-Certified Physical Drives Causing Warnings
if (Test-Path "C:\Program Files\Dell\SysMgt\sm\stsvc.ini") { $iniFile = "C:\Program Files\Dell\SysMgt\sm\stsvc.ini" }
if (Test-Path "C:\Program Files (x86)\Dell\SysMgt\sm\stsvc.ini") { $iniFile = "C:\Program Files (x86)\Dell\SysMgt\sm\stsvc.ini" }

$iniContents = Get-Content $iniFile

if ($iniContents.Contains("NonDellCertifiedFlag=no")) {
    Write-Host "NonDellCertifiedFlag already set to no."
} else {
    if ($iniContents.Contains("NonDellCertifiedFlag=yes")) {
        $iniContentsNew = $iniContents.Replace("NonDellCertifiedFlag=yes", "NonDellCertifiedFlag=no")
    } else {
        $iniContentsNew = $iniContents | Foreach-Object {
            $_ # Send the current line to output
            if ($_ -match "EnclosurePollingInterval=30") {
                ""
                "; nonDellCertified flag for blocking all non-dell certified alerts."
                "NonDellCertifiedFlag=no"
            }
        }
    }
    $iniContentsNew | Set-Content $iniFile
    Restart-Service dcstor64
}

Write-Host "Done!"`n