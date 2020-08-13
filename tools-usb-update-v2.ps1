# Set path
#$Path = -join ($PSScriptRoot.Substring(0,2), "\install\Tools\*\*")
$Path = $PSScriptRoot

# Ensure Temp directory exists
New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null

# Download latest N-able Agent installer
$NableContainer = "C:\Temp\WindowsAgentSetupContainer.exe"
$LatestNableFile = "C:\Temp\LatestNableFile.exe"
$NableFile = "C:\Temp\WindowsAgentSetup.exe"
$TempNableFile = "C:\Temp\TempWindowsAgentSetup.exe"
Write-Host "Checking latest version of N-able agent..."`n -ForegroundColor DarkYellow
$ProgressPreference = 'SilentlyContinue'
(Invoke-webrequest -URI "https://nable.415group.com/dms/FileDownload?customerID=102&softwareID=101" -OutFile "$NableContainer").Content
If (-Not (Test-Path $NableContainer)) {
    Write-Host "File did not download. Please try again."
    Read-Host -Prompt "Press Enter to exit"
    Exit
    }

# Extract N-able installer
Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x" ,$NableContainer, "-oC:\Temp", "-aoa" -Wait -WindowStyle Hidden
Move-Item $NableFile $LatestNableFile -Force

# Check and display latest version
$LatestNableVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$LatestNableFile").FileVersion
Write-Host "Latest version of N-able Agent: $LatestNableVersion"`n

# Check if N-able installers are up to date
Write-Host "Checking current N-able installers..."`n
Get-ChildItem -Path $Path -Include *WindowsAgentSetup.exe -Recurse | Sort | ForEach-Object {
    Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x" ,"`"$_`"", "-oC:\Temp", "-aoa" -Wait -WindowStyle Hidden
    Move-Item $NableFile $TempNableFile -Force
    $NableVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$TempNableFile").FileVersion
    Write-Host "Current N-able Agent version is: $NableVersion"
    If ($NableVersion -lt "$LatestNableVersion") {
        Write-Host "$_ is out of date."`n -ForegroundColor Cyan
        $CustomerID = Get-ChildItem "$_" | % {$_.Name.Split('W')[0]}
        $NableURL = "https://nable.415group.com/dms/FileDownload?customerID=${customerID}&softwareID=101"
        Write-Host "Updating from $NableVersion to $LatestNableVersion..."`n -ForegroundColor Yellow
        (New-Object System.Net.WebClient).DownloadFile($NableURL, $_)
        Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x" ,"`"$_`"", "-oC:\Temp", "-aoa" -Wait -WindowStyle Hidden
        Move-Item $NableFile $TempNableFile -Force
        $NableVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$TempNableFile").FileVersion
    }
    If ($NableVersion -eq "$LatestNableVersion") {
        Write-Host "$_ is up to date."`n -ForegroundColor Green
    } else {
        Write-Host "$_ failed to update."`n -ForegroundColor Red
    }
    Remove-Item $TempNableFile -Force
    Remove-Item $NableFile -Force -ErrorAction SilentlyContinue    
}

# Download latest Webroot installer
$WebrootURL = "https://anywhere.webrootcloudav.com/zerol/wsasme.exe"
$LatestWebrootFile = "C:\Temp\wsasme.exe"
Write-Host "Checking latest version of Webroot..."`n -ForegroundColor DarkGreen
(New-Object System.Net.WebClient).DownloadFile($WebrootURL, $LatestWebrootFile)

# Check if Webroot installers are up to date
$LatestWebrootVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$LatestWebrootFile").FileVersion
Write-Host "Latest version of Webroot: $LatestWebrootVersion" `n
Write-Host "Checking current Webroot installers..."`n
Get-ChildItem -Path $Path -Exclude *Setup.exe -Recurse | Sort | Where-Object { $_.Name -match "[a-z\d]{20}\.exe" } | ForEach-Object { 
    $WebrootVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$_").FileVersion
    If ($WebrootVersion -lt $LatestWebrootVersion) {
        Write-Host "$_ is out of date"`n -ForegroundColor Red
        Write-Host "Updating..."`n -ForegroundColor Yellow
        Copy-Item $LatestWebrootFile $_.FullName
        $WebrootVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$_").FileVersion
        If ($WebrootVersion -eq $LatestWebrootVersion) {
            Write-Host "$_ is now up to date."`n -ForegroundColor Green
        } else {
            Write-Host "$_ failed to update."`n -ForegroundColor Red
        }
    } else {
        Write-Host "$_ is up to date."`n -ForegroundColor Green
    }
}

# Clean up
Remove-Item $LatestNableFile, $NableContainer, $LatestWebrootFile -Force

Read-Host -Prompt "Press Enter to exit"