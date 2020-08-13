# Set path
#$Path = -join ($PSScriptRoot.Substring(0,2), "\install\Tools\*\*")
$Path = $PSScriptRoot

# Download latest N-able Agent installer
$NableContainer = "$env:TEMP\WindowsAgentSetupContainer.exe"
$NableOutput = "$env:TEMP\WindowsAgentSetup.exe"
Write-Host "Checking latest version of N-able agent..."`n
(Invoke-webrequest -URI "https://nable.415group.com/dms/FileDownload?customerID=102&softwareID=101" -OutFile "$NableContainer").Content

# Extract N-able installer
Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x" ,$NableContainer, "-o$env:TEMP", "-aoa" -Wait -WindowStyle Hidden

# Check if N-able installers are up to date
$LatestNable = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$NableOutput").FileVersion
Write-Host "Latest version of N-able Agent: $LatestNable"`n
Write-Host "Checking current N-able installers..."`n
Get-ChildItem -Path $Path -Include *WindowsAgentSetup.exe -Recurse | Sort | ForEach-Object { 
    Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x" ,$_, "-o$env:TEMP", "-aoa" -Wait -WindowStyle Hidden
    $NableVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$NableOutput").FileVersion
    If ($NableVersion -lt "$LatestNable") {
        Write-Host "$_ is out of date."`n -ForegroundColor Cyan
        $CustomerID = Get-ChildItem $_ | % {$_.Name.Split('W')[0]}
        $NableURL = "https://nable.415group.com/dms/FileDownload?customerID=${customerID}&softwareID=101"
        Write-Host "Updating..."`n -ForegroundColor Yellow
        (New-Object System.Net.WebClient).DownloadFile($NableURL, $_)
        Start-Process "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x" ,$_, "-o$env:TEMP", "-aoa" -Wait -WindowStyle Hidden
        $NableVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$NableOutput").FileVersion
        If ($NableVersion -eq "$LatestNable") {
            Write-Host "$_ is now up to date."`n -ForegroundColor Green
        } else {
            Write-Host "$_ failed to update."`n -ForegroundColor Red
        }
    } else {
        Write-Host "$_ is up to date."`n -ForegroundColor Green
    }
}

# Download latest Webroot installer
$WebrootURL = "https://anywhere.webrootcloudav.com/zerol/wsasme.exe"
$WebrootOutput = "$env:TEMP\wsasme.exe"
Write-Host "Checking latest version of Webroot..."`n
(New-Object System.Net.WebClient).DownloadFile($WebrootURL, $WebrootOutput)

# Check if Webroot installers are up to date
$LatestWebroot = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$WebrootOutput").FileVersion
Write-Host "Latest version of Webroot: $LatestWebroot" `n
Write-Host "Checking current Webroot installers..."`n
Get-ChildItem -Path $Path -Exclude *Setup.exe -Recurse | Sort | Where-Object { $_.Name -match "[a-z\d]{20}\.exe" } | ForEach-Object { 
    $WebrootVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$_").FileVersion
    If ($WebrootVersion -lt $LatestWebroot) {
        Write-Host "$_ is out of date"`n -ForegroundColor Red
        Write-Host "Updating..."`n -ForegroundColor Yellow
        Copy-Item $WebrootOutput $_.FullName
        $WebrootVersion = [System.Version][System.Diagnostics.FileVersionInfo]::GetVersionInfo("$_").FileVersion
        If ($WebrootVersion -eq $LatestWebroot) {
            Write-Host "$_ is now up to date."`n -ForegroundColor Green
        } else {
            Write-Host "$_ failed to update."`n -ForegroundColor Red
        }
    } else {
        Write-Host "$_ is up to date."`n -ForegroundColor Green
    }
}

Read-Host -Prompt "Press Enter to exit"