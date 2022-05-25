# Parameters for excluding app installs (broken atm...)
#param($Exclude)

$LastUpdated = '05/20/2022  '

# Set window title
$host.UI.RawUI.WindowTitle = "New PC Setup Script - $env:COMPUTERNAME"

# Set C:\Temp as TEMP variable
$env:TEMP = "C:\Temp"
New-Item -Path $env:TEMP -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

# Start script logging
$LogFile = "$env:TEMP\new-pc-setup_$(Get-Date -Format 'yyyy-MM-ddTHH_mm_ss').log"
Try {Start-Transcript -Path $LogFile -ErrorAction Stop | Out-Null}
Catch {Start-Transcript -Path $LogFile | Out-Null}

# Disable progress bar for faster downloads
$global:ProgressPreference = 'SilentlyContinue'

# Beep alert function
function BeepBoop {
    For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]174)}
    Start-Sleep 2
    [console]::Beep();[console]::Beep()
    Start-Sleep 2
    For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]175)}
}

# Download function
function Download {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$URL,
	    [Parameter(Mandatory)][string]$Name,
	    [Parameter(Mandatory)][string]$Extension
	)
    $Error.Clear()
    if ($URL -match "\....$") {
		$Filename = Split-Path $URL -Leaf
	} else {
		$Filename = $Name + ".$Extension"
	}
    $Output = $env:TEMP + "\$Filename" -replace '...$',$Extension
    #$Name = $Name -csplit '(?=[A-Z])' -ne '' -join ' '
    #Write-Host "Downloading $Name..."`n
    if (!(Test-Path $Output)) {(New-Object System.Net.WebClient).DownloadFile($URL, $Output)}
    if ($Error.count -gt 0) {Write-Host "Retrying..."`n; $Error.Clear(); (New-Object System.Net.WebClient).DownloadFile($URL, $Output)}
    if ($Error.count -gt 0) {Write-Warning "$Name download failed";Write-Host}
    New-Variable -Name $Name"Output" -Value $Output -Scope Global -Force
}

# Progress animation function
function ProgressAnimation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Process
	)
$Counter = 0
    Do {
        Write-Host . -NoNewline
        Start-Sleep 3
        $Counter += 1
    } Until ((Get-Process $Process -ErrorAction SilentlyContinue) -or ($Counter -eq 5))
    Do {
        Write-Host . -NoNewline
        Start-Sleep 3
    } Until (-not(Get-Process $Process -ErrorAction SilentlyContinue))
    Write-Host `n
}

# Check for internet connection
Write-Host "Checking for internet connection..."`n
if (-not(Test-NetConnection 9.9.9.9).PingSucceeded) {
    Write-Warning "Internet not detected. Please connect then restart script."
    BeepBoop
    Read-Host "Press ENTER to exit"
    Exit 1
}

# Check if script name is correct
if ($MyInvocation.MyCommand.Name -notlike "new-pc-setup.ps1") {
    Write-Warning "Script name is not correct and may cause issues. Please rename it to new-pc-setup.ps1 and restart it."
    BeepBoop
    Read-Host "Press ENTER to exit"
    Exit 2
}

# Download latest version of script and replace it
Write-Host "Checking if newer version of script is available..."`n
$OldScript = $MyInvocation.MyCommand.Path
$DriveLetter = $PSScriptRoot.Substring(0,3)
if ($DriveLetter -eq "C:\") {
    $NewScript = $OldScript
} else {
    $NewScript = -join ($DriveLetter, $MyInvocation.MyCommand)
}
$OldScriptHash = Get-FileHash $OldScript -Algorithm SHA1
Invoke-WebRequest https://raw.githubusercontent.com/RaySmalley/NewPCSetup/main/new-pc-setup.ps1 -UseBasicParsing -OutFile $NewScript
$NewScriptHash = Get-FileHash $NewScript -Algorithm SHA1
if ($OldScript -ne $NewScript) {Remove-Item $OldScript -Force}
if ($NewScriptHash.Hash -ne $OldScriptHash.Hash) {
    $ScriptUpdated = $true
    Write-Host "Script updated to latest version"`n
    Start-Sleep 2
} else {
    $ScriptUpdated = $false
    Write-Host "No update available"`n
}

# Test for elevation / restart script
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$NewScript`" -Exclude $Exclude" -Verb RunAs
    Exit
} else {
    if ($ScriptUpdated) {
        Write-Host Restarting script...`n
        Start-Sleep 1
        & "$PSCommandPath" ### I believe this causes the script to run twice
    }
}

Write-Host "# PC Setup Script #" -ForegroundColor Cyan
Write-Host "# Ray Smalley     #" -ForegroundColor Cyan
Write-Host "# $LastUpdated    #"`n -ForegroundColor Cyan

# Download and extract Windows 10 Configuration Designer setup files
#if ($DriveLetter -ne "C:\") {
#    Invoke-WebRequest https://raw.githubusercontent.com/RaySmalley/PowerShell/master/new-pc-setup.zip -OutFile $env:TEMP\new-pc-setup.zip
#    Expand-Archive -Path $env:TEMP\new-pc-setup.zip -DestinationPath $PSScriptRoot -Force
#}

# Check if script is old
$MasterLastUpdated = ((Invoke-WebRequest https://raw.githubusercontent.com/RaySmalley/PowerShell/master/new-pc-setup.ps1 -UseBasicParsing).ToString() -split "[`r`n]" | Select-String -Pattern "(0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])[- /.](19|20)[0-9]{2}").Matches[0].Value
if ([datetime]$MasterLastUpdated -gt [datetime]$LastUpdated) {
    Write-Warning "Script is out of date. See Ray for latest version."
}

# Rename computer
if (-not(Test-Path $env:TEMP\old-hostname.txt)) {
    BeepBoop
    Write-Host "Current computer name: $env:COMPUTERNAME"
    $NewName = Read-Host "Enter new computer name (leave blank to keep current name)"
    if ($NewName) {
        Rename-Computer -NewName $NewName | Out-Null
        Write-Host
        Write-Host "Renamed PC from $env:COMPUTERNAME to $NewName"`n
        Set-Content -Path $env:TEMP\old-hostname.txt -Value $env:COMPUTERNAME
    } else {
        Write-Host "Computer Name: $env:COMPUTERNAME"`n
    }
}

# Disable UAC (temporarily)
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force | Out-Null

# Set Time
Write-Host "Setting time..."`n
Set-TimeZone -Name "Eastern Standard Time"
Restart-Service "Windows Time"
w32tm /resync | Out-Null

# Remove local admin password if present
if (Get-LocalUser $env:USERNAME -ErrorAction SilentlyContinue) {Set-LocalUser -name "$env:USERNAME" -Password ([SecureString]::New())}

# Change power settings
Write-Host "Changing power settings..."`n
powercfg /change monitor-timeout-ac 20
powercfg /change standby-timeout-ac 0
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 # USB Selective Suspend

# Delete Edge shortcut from desktop
Remove-Item "C:\Users\*\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue

# Allow script to run after reboot
$StartupScript = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\pc-setup-autostart.bat"
if (-not (Test-Path $StartupScript)) {
    New-Item $StartupScript -Force | Out-Null
    Add-Content $StartupScript "Title New PC Setup Script - $env:COMPUTERNAME"
    Add-Content $StartupScript "PowerShell Set-ExecutionPolicy Bypass -Force"
    Add-Content $StartupScript "PowerShell -File $PSCommandPath"
}

# Install latest Windows 10 build if not up to date
$CurrentBuild = [System.Environment]::OSVersion.Version.Build
switch ($CurrentBuild) {
    19044 { $FriendlyBuild = "21H2" }
    19043 { $FriendlyBuild = "21H1" }
    19042 { $FriendlyBuild = "20H2" }
    19041 { $FriendlyBuild = "2004" }
    18363 { $FriendlyBuild = "1909" }
    18362 { $FriendlyBuild = "1903" }
    17763 { $FriendlyBuild = "1809" }
    17134 { $FriendlyBuild = "1803" }
    16299 { $FriendlyBuild = "1709" }
    15063 { $FriendlyBuild = "1703" }
    14393 { $FriendlyBuild = "1607" }
    10586 { $FriendlyBuild = "1511" }
}
if ($CurrentBuild -lt 19044) {
    Write-Host "Current Windows 10 build is $FriendlyBuild"`n -ForegroundColor Yellow
    Download -Name Windows10Upgrade -URL https://go.microsoft.com/fwlink/?LinkID=799445 -Extension exe
    Write-Host "Starting Windows 10 Update Assistant..."`n
    Start-Process -FilePath $Windows10UpgradeOutput -ArgumentList /SkipEULA, /NoRestartUI -Verb RunAs -Wait
    Start-Sleep 30
}

# Windows Updates
Write-Host "Checking for Windows Updates..."`n
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module PSWindowsUpdate -Force
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    if (Get-WindowsUpdate) {
        Write-Host "Windows Updates found. Installing..."`n
        #Shutdown -r -t 1200
        Get-WindowsUpdate -AcceptAll -Install -AutoReboot
        Write-Host
        Write-Host "Windows Updates installed"`n
        Start-Sleep 10
        #Shutdown -a
    } else {
        Write-Host "No updates available"`n
    }
} else {
    Write-Warning "Windows Update Module not installed. Cannot look for updates. Try restarting computer/script."
}

# Dell Command Update
if ((Get-WmiObject -Class:Win32_ComputerSystem).Manufacturer -like "*Dell*") {
    [System.Version]$dcuLatest = "4.5.0"
    $dcuVersion = [System.Version](Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object {$_.DisplayName -like "*Command | Update*"}).DisplayVersion
    if (-not $dcuVersion) {$dcuVersion = [System.Version](Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object {$_.DisplayName -like "*Command | Update*"}).DisplayVersion}
    if ($dcuVersion -lt $dcuLatest) {
        # Download/Install
        Write-Host "Downloading latest Dell Command Update..."`n
        Download -Name DellCommandUpdate -URL https://dl.dell.com/FOLDER08334704M/2/Dell-Command-Update-Windows-Universal-Application_601KT_WIN_4.5.0_A00_01.EXE -Extension exe
        Write-Host "Installing Dell Command Update" -NoNewline
        #Expand-Archive -Path $DellCommandUpdateOutput -DestinationPath $env:TEMP\DCU -Force
        ProgressAnimation -Process DellCommandUpdateApp_Setup
        Start-Process -FilePath $DellCommandUpdateOutput -ArgumentList /s -Wait
    }
    # Run DCU
    if ((Test-Path "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe") -or (Test-Path "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe")) {
        Write-Host "Running Dell Command Update... (If DCU searches longer than a few minutes just close the window to skip.)"
        Start-Process "C:\Program Files*\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList /applyUpdates, -reboot=enable -Wait
        Start-Sleep 15
        Write-Host
    } else {
        Write-Warning "Dell Command Update not installed. Skipping..."; Write-Host
    }
}

# Install Google Chrome
if (-not (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*" | Where {$_.PSChildName -match "chrome"})) {
    if ($Exclude -notmatch "Chrome") {
        Write-Host "Installing Google Chrome" -NoNewline
        Download -Name GoogleChrome -URL http://dl.google.com/chrome/install/375.126/chrome_installer.exe -Extension exe
        Start-Process -FilePath "$GoogleChromeOutput" -ArgumentList /silent, /install
        ProgressAnimation -Process chrome_installer
        if (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*" | Where {$_.PSChildName -match "chrome"}) {
            Write-Host "Google Chrome installation complete"`n
        } else {
            Write-Warning "Google Chrome installation failed"; Write-Host
        }
    } else {
        Write-Host "Google Chrome excluded. Skipping..."`n
    }
} else {
    Write-Host "Google Chrome already installed. Skipping..."`n
}

# Install Adobe Reader
if (-not (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*" | Where {$_.PSChildName -match "AcroRd32"}) -or ($Exclude -match "Adobe")) {
    if ($Exclude -notmatch "Adobe") {   
        Write-Host "Installing Adobe Reader..."`n
        $ChocoOutput = "$env:temp\installChocolatey.ps1"
        Invoke-WebRequest -Uri 'https://chocolatey.org/install.ps1' -UseBasicParsing -OutFile $ChocoOutput
        $Result = Get-AuthenticodeSignature -FilePath $ChocoOutput
        if ($Result.Status -ne 'Valid') {
            Write-Warning "Chocolatey installation script damaged"
            BeepBoop
            Read-Host "Press ENTER to exit"
            Exit 4
        }
        $env:ChocolateyInstall='C:\ProgramData\chocoportable'
        Start-Process -FilePath PowerShell -ArgumentList "-noprofile -ExecutionPolicy Bypass -File ""$ChocoOutput""" -Wait -WindowStyle Hidden
        C:\ProgramData\chocoportable\choco.exe install adobereader -params '"/DesktopIcon /UpdateMode:3"' -y --force | Out-Null
        if (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*" | Where {$_.PSChildName -match "AcroRd32"}) {
            Write-Host "Adobe Reader installation complete"`n
        } else {
            Write-Warning "Adobe Reader installation failed"; Write-Host
        }
    } else {
        Write-Host "Adobe Reader excluded. Skipping..."`n
    }
} else {
    Write-Host "Adobe Reader already installed. Skipping..."`n
}

# Download Office Deployment Toolkit
function Get-ODTUri {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    $dcuURL = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $dcuURL -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to ODT: $dcuURL with error $_"
        Break
    }
    finally {
        $ODTUri = $response.links | Where-Object {$_.outerHTML -like "*click here to download manually*"}
        Write-Output $ODTUri.href
    }
}

if (((Get-ChildItem "$PSScriptRoot\install\Office365\setup.exe" -ErrorAction SilentlyContinue).LastAccessTime -lt (Get-Date).AddMonths(-1)) -or (-not(Test-Path "$PSScriptRoot\install\Office365\setup.exe" -ErrorAction SilentlyContinue))) {
    New-Item -ItemType Directory -Force -Path $PSScriptRoot\install\Office365 | Out-Null
    Write-Host "Downloading Office Deployment Tool..."`n
    $odtURL = $(Get-ODTUri)
    Invoke-WebRequest -UseBasicParsing -Uri $odtURL -OutFile $env:TEMP\ODT.exe
    if (-not (Test-Path $env:TEMP\ODT.exe)) {
        Write-Warning "ODT download failed"
        Write-Warning "Not found: $env:TEMP\ODT.exe"
        BeepBoop
        Read-Host "Press ENTER to exit"
        Exit 5
    }
    Start-Process -FilePath "$env:TEMP\ODT.exe" -ArgumentList /quiet, /extract:""$PSScriptRoot""\install\Office365\ -Wait
    Remove-Item $PSScriptRoot\install\Office365\*.xml -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path $PSScriptRoot\install\Office365\setup.exe)) {
        Write-Warning "ODT Extraction failed"
        Write-Warning "Not found: $PSScriptRoot\install\Office365\setup.exe"
        BeepBoop
        Read-Host "Press ENTER to exit"
        Exit 6
    }
}

# Remove Office trials if installed
$OfficeRemovalXML = @'
<Configuration>
  <Display Level="None" AcceptEULA="True" />
  <Logging Level="Standard" Path="$env:TEMP\OfficeRemovalLogs" />
  <Remove All="TRUE" />
</Configuration>
'@
$OfficeRemovalXML > "$PSScriptRoot\install\Office365\RemoveOffice.xml"

if (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where {$_.DisplayName -match "es-es"}){
    Write-Host "Removing Office trial..."`n
    Start-Process -FilePath "$PSScriptRoot\install\Office365\setup.exe" -ArgumentList /configure, "$PSScriptRoot\install\Office365\RemoveOffice.xml" -WindowStyle Hidden -Wait
    if (-not (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where {$_.DisplayName -match "es-es"})) {
        Write-Host "Office trial removal complete. Restarting computer..."`n
        Start-Sleep 5
        Restart-Computer
    } else {
        Write-Warning "Office trial removal failed. Please uninstall Office trial manually and restart script."`n
        BeepBoop
        Read-Host "Press ENTER to exit"
        Exit 7
    }
}

# Download and install Office 365
function OfficeIsNotInstalled {
    (-not(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where {$_.DisplayName -match "Microsoft 365"}))
}

$Office365BusinessRetailXML = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current" SourcePath="$PSScriptRoot\install\Office365">
    <Product ID="O365BusinessRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Updates Enabled="TRUE" />
  <Display Level="Full" AcceptEULA="TRUE" />
  <Logging Level="Standard" Path="$env:TEMP\OfficeInstallLogs" />
</Configuration>
"@
$Office365BusinessRetailXML > "$PSScriptRoot\install\Office365\Office365BusinessRetail.xml"

if (-not (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where {$_.DisplayName -match "es-es"})) {
    if (OfficeIsNotInstalled) {
        $LocalDiskSpace = (Get-Volume ($DriveLetter.Substring(0,1))).SizeRemaining
        $OfficeFilesSize = (Get-ChildItem -Recurse "$PSScriptRoot\install\Office365" -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
        if ($LocalDiskSpace -gt $OfficeFilesSize -and $LocalDiskSpace -ge 8GB) {
            if ($OfficeFilesSize -lt 3GB) {
                Write-Host "Downloading Office 365..."`n
                Start-Process -FilePath "$PSScriptRoot\install\Office365\setup.exe" -ArgumentList /download, "$PSScriptRoot\install\Office365\Office365BusinessRetail.xml" -WindowStyle Hidden -Wait
                Write-Host "Office 365 download finished"`n
                $OfficeFilesSize = (Get-ChildItem -Recurse "$PSScriptRoot\install\Office365" -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
                if ($OfficeFilesSize -lt 3GB) {
                    Write-Warning "Office download doesn't appear complete. Restarting computer to try again..."
                    for ($i = 5;$i -ne 0) {
                        Write-Host $i
                        $i -= 1
                        Start-Sleep 1
                        if ($i -eq 0) {
                            Write-Host "See ya soon!"
                            Restart-Computer -Force
                        }
                    }
                }
            }
        } else {
            Write-Warning "Not enough space on $DriveLetter to download Office"
            BeepBoop
            Read-Host "Press ENTER to continue"
        }
        $OfficeFilesSize = (Get-ChildItem -Recurse "$PSScriptRoot\install\Office365" -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum
        if ($OfficeFilesSize -gt 3GB) {
            Write-Host "Installing Office 365..."`n
            Start-Process -FilePath "$PSScriptRoot\install\Office365\setup.exe" -ArgumentList /configure, "$PSScriptRoot\install\Office365\Office365BusinessRetail.xml" -WindowStyle Hidden -Wait
        }
        if (-not(OfficeIsNotInstalled)) {
            Write-Host "Office 365 installation complete"`n
        } else {
            Write-Warning "Office 365 installation failed"
            Write-Warning "Please review logs at $env:TEMP\OfficeInstallLogs"
            BeepBoop
            Read-Host "Press ENTER to continue"
        }
    } else {
        Write-Host "Office 365 already installed. Skipping..."`n
    }
}

# End prompt
Write-Host "Done! Don't forget to install N-able Agent and Antivirus!"`n
BeepBoop
Read-Host -Prompt "Press ENTER to wrap things up"

# Add 415 Group local admin
if (-not (Get-LocalUser 415Admin -ErrorAction SilentlyContinue)) {
    Write-Host "Creating 415Admin user..."`n
    net user 415Admin * /add 
    net localgroup Administrators 415Admin /add
    wmic useraccount WHERE "Name='415Admin'" set PasswordExpires=false
    Write-Host "415Admin local admin created"`n
} else {
    Write-Host "Creating a password for 415Admin user..."`n
    net user 415Admin *
    Write-Host "Password created"`n
}

# Remove McAfee products
Write-Host "Checking for McAfee products..."`n
function McAfee {Get-Package -Name *McAfee* -ErrorAction SilentlyContinue}
if (McAfee) {
    Write-Host "McAfee products found. Uninstalling..."`n
    Download -Name McAfeeRemover -URL https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe -Extension exe
    Write-Host "Opening McAfee Consumer Product Removal tool..."`n
    Start-Process $McAfeeRemoverOutput -Wait
    McAfee | ForEach {& $_.Meta.Attributes['UninstallString'] /s; Write-Host "Removing $_.Name"`n}
    if (-not(McAfee)) {
        Write-Host "McAfee removal successful"`n
    } else {
        Write-Warning "McAfee removal failed. Please remove manually."; Write-Host
    }
}

# Cleanup
if (Test-Path $StartupScript) {Remove-Item $StartupScript -Force -ErrorAction SilentlyContinue}
if (Test-Path $Windows10UpgradeOutput) {Remove-Item $Windows10UpgradeOutput -Force -ErrorAction SilentlyContinue}
if (Test-Path $DellCommandUpdateOutput) {Remove-Item $DellCommandUpdateOutput -Force -ErrorAction SilentlyContinue}
if (Test-Path $GoogleChromeOutput) {Remove-Item $GoogleChromeOutput -Force -ErrorAction SilentlyContinue}
if (Test-Path $McAfeeRemoverOutput) {Remove-Item $McAfeeRemoverOutput -Force -ErrorAction SilentlyContinue}
Remove-Item "$env:TEMP\AdobeReaderSetup.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\new-pc-setup.zip" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\DCU" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\ODT.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\installChocolatey.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\chocolatey" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\ProgramData\chocoportable" -Recurse -Force -ErrorAction SilentlyContinue
if (($DriveLetter -eq "C:\") -and (-not(OfficeIsNotInstalled))) {
        Remove-Item "$PSScriptRoot\install" -Recurse -Force -ErrorAction SilentlyContinue
}

# Re-enable UAC
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 1 -Force | Out-Null

Stop-Transcript

Exit 0