$ProgressPreference = 'SilentlyContinue'

# .Net check
if ((Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -lt 379893) {
    Write-Output ".NET Framework 4.5.2 or greater not installed. Exiting..."
    Exit 1
}

# PowerShell version check
if ([Version]$host.version -lt [Version]5.1.00000.0) {
    Write-Output "PowerShell version is less than 5.1. Attempting to install..."
    $os_version = [Version](Get-Item -Path "$env:SystemRoot\System32\kernel32.dll").VersionInfo.ProductVersion
    $host_string = "$($os_version.Major).$($os_version.Minor)-$($env:PROCESSOR_ARCHITECTURE)"
    switch($host_string) {
        "6.1-x86" {
            Invoke-WebRequest -UseBasicParsing -Uri "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7-KB3191566-x86.zip" -OutFile $env:TEMP\Win7-KB3191566-x86.zip
            Expand-Archive -Path $env:TEMP\Win7-KB3191566-x86.zip -DestinationPath $env:TEMP -Force
            Start-Process -FilePath $env:TEMP\Install-WMF5.1.ps1 -Wait
        }
        "6.1-AMD64" {
            Invoke-WebRequest -UseBasicParsing -Uri "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip" -OutFile $env:TEMP\Win7AndW2K8R2-KB3191566-x64.zip
            Expand-Archive -Path $env:TEMP\Win7AndW2K8R2-KB3191566-x64.zip -DestinationPath $env:TEMP -Force
            Start-Process -FilePath $env:TEMP\Install-WMF5.1.ps1 -Wait
        }
        "6.2-x86" {
            Invoke-WebRequest -UseBasicParsing -Uri "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu" -OutFile $env:TEMP\Win8.1-KB3191564-x86.msu
        }
        "6.2-AMD64" {
            Invoke-WebRequest -UseBasicParsing -Uri "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/W2K12-KB3191565-x64.msu" -OutFile $env:TEMP\W2K12-KB3191565-x64.msu
        }
        "6.3-x86" {
            Invoke-WebRequest -UseBasicParsing -Uri "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1-KB3191564-x86.msu" -OutFile $env:TEMP\Win8.1-KB3191564-x86.msu
        }
        "6.3-AMD64" {
            Invoke-WebRequest -UseBasicParsing -Uri "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu" -OutFile $env:TEMP\Win8.1AndW2K12R2-KB3191564-x64.msu
        }
    }

    shutdown -r -t $([int]([datetime]"2AM"-(Get-Date).AddDays(-1)).TotalSeconds)
} else {    
    if (-Not (Get-Module -ListAvailable -Name CredentialManager)) {Install-Module -Name CredentialManager -Force}
    Import-Module -Name CredentialManager -Force
    (Get-StoredCredential -AsCredentialObject) | Select TargetName,UserName | Where {$_ -match "administrator"}
}

# Clean up

Remove-Item $env:TEMP\*.msu -Force -ErrorAction SilentlyContinue
Remove-Item $env:TEMP\Win7* -Force -ErrorAction SilentlyContinue
