# Start script logging
Start-Transcript -Path $PSScriptRoot\new-pc-setup.log | Out-Null

# Download latest version of script
$global:ProgressPreference = 'SilentlyContinue'
$OldScript = $MyInvocation.MyCommand.Path
$DriveLetter = $PSScriptRoot.Substring(0,3)
if ($DriveLetter -eq "C:\") {
    $NewScript = $OldScript
} else {
    $NewScript = -join ($DriveLetter, $MyInvocation.MyCommand)
}
Invoke-WebRequest https://raw.githubusercontent.com/RaySmalley/PowerShell/master/new-pc-setup.ps1 -OutFile $NewScript
if ($OldScript -ne $NewScript) {Remove-Item $OldScript -Force}

# Test for elevation
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$NewScript`"" -Verb RunAs
    Exit
}

Write-Host '# PC Setup Script           #'
Write-Host '# Ray Smalley               #'
Write-Host '# 2020                      #'`n

# Download and extract Windows 10 Configuration Designer setup files
if ($DriveLetter -ne "C:\") {
    Invoke-WebRequest https://raw.githubusercontent.com/RaySmalley/PowerShell/master/new-pc-setup.zip -OutFile $env:TEMP\new-pc-setup.zip
    Expand-Archive -Path $env:TEMP\new-pc-setup.zip -DestinationPath $PSScriptRoot -Force
}

# Disable UAC
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force | Out-Null

# Remove 415Admin password if present
if (Get-LocalUser 415Admin -ErrorAction SilentlyContinue) {Set-LocalUser -name "415Admin" -Password ([securestring]::new())}

# Allow script to run after reboot
$StartupScript = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\pc-setup-autostart.bat"
New-Item $StartupScript -Force | Out-Null
Add-Content $StartupScript "PowerShell Set-ExecutionPolicy Bypass -Force"
Add-Content $StartupScript "PowerShell -File $PSCommandPath"

# Change Power Settings
Write-Host "Changing power settings..."`n
powercfg /change monitor-timeout-ac 20
powercfg /change standby-timeout-ac 0
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 # USB Selective Suspend
Write-Host "Power settings changed."`n

# Rename Computer
if ($env:COMPUTERNAME -match "DESKTOP") {
    Write-Host "Renaming computer..."`n
    For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]174)}
    [console]::Beep();[console]::Beep()
    Start-Sleep 3
    For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]175)}
    $NewName = Read-Host "Enter new computer name: "
    Rename-Computer -NewName $NewName | Out-Null
    Write-Host "Renamed PC from $env:COMPUTERNAME to $NewName"`n
}

# Windows Updates
Write-Host "Checking for Windows Updates..."`n
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { 
    Write-Host "Installing Package Provider: NuGet..."
    Install-PackageProvider -Name NuGet -Force
    Write-Host "Installing Module: PSWindowsUpdate..."
    Install-Module PSWindowsUpdate -Force
}
if (Get-WindowsUpdate -AcceptAll -Install -AutoReboot) {
    Write-Host "Windows Updates installed."`n
} else {
    Write-Host "No updates available."`n
}

Start-Sleep 10

# Download Office Deployment Toolkit
function Get-ODTUri {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    $URL = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $URL -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to ODT: $URL with error $_."
        Break
    }
    finally {
        $ODTUri = $response.links | Where-Object {$_.outerHTML -like "*click here to download manually*"}
        Write-Output $ODTUri.href
    }
}
if (-Not (Test-Path $PSScriptRoot\install\Office365)) {New-Item -ItemType Directory -Force -Path $PSScriptRoot\install\Office365 | Out-Null}
Write-Host "Downloading latest version of Office 365 Deployment Tool (ODT)."`n
$ODTURL = $(Get-ODTUri)
Invoke-WebRequest -UseBasicParsing -Uri $ODTURL -OutFile $env:TEMP\ODT.exe
Start-Process -FilePath "$env:TEMP\ODT.exe" -ArgumentList /quiet,/extract:$PSScriptRoot\install\Office365\ -Wait
Remove-Item "$env:TEMP\ODT.exe" -Force
Remove-Item $PSScriptRoot\install\Office365\*.xml -Force -ErrorAction SilentlyContinue

# Remove Office trials if installed
$OfficeRemovalXML = @'
<Configuration>
  <Display Level="None" AcceptEULA="True" />
  <Remove All="TRUE" />
</Configuration>
'@
$OfficeRemovalXML > "$PSScriptRoot\install\Office365\RemoveOffice.xml"

if (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where { $_.DisplayName -match "es-es" }){
    Write-Host "Removing Office trial..."`n
    Start-Process -FilePath "$PSScriptRoot\install\Office365\setup.exe" -ArgumentList /configure,"$PSScriptRoot\install\Office365\RemoveOffice.xml" -WindowStyle Hidden -Wait
    if (-Not (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where { $_.DisplayName -match "es-es" })) {
        Write-Host "Office trial removal complete. Restarting computer..."`n
        Start-Sleep 5
        Restart-Computer
    } else {
        For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]174)}
        [console]::Beep();[console]::Beep()
        Start-Sleep 3
        For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]175)}
        Write-Host "Office trial removal failed."`n -ForegroundColor Red
        Read-Host -Prompt "Please uninstall Office trial manually and restart script."
        Exit 2
    }
}

# Install Office 365

### TEMPORARY ###
if (Test-Path $PSScriptRoot\install\Office365\Office365BusinessRetail64) { 
    Move-Item $PSScriptRoot\install\Office365\Office365BusinessRetail64\Office $PSScriptRoot\install\Office365\ | Out-Null
    Remove-Item $PSScriptRoot\install\Office365\Office365BusinessRetail* -Force -Recurse
}
### TEMPORARY ###

$Office365BusinessRetailXML = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
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

if (-Not (Test-Path "$PSScriptRoot\install\Office365\Office\Data\*.cab")) {
    Write-Host "Downloading Office 365..."`n
    Start-Process -FilePath "$PSScriptRoot\install\Office365\setup.exe" -ArgumentList /download,"$PSScriptRoot\install\Office365\Office365BusinessRetail.xml" -WindowStyle Hidden -Wait
    Write-Host "Office 365 download complete."`n
}
if (-not (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where { $_.DisplayName -match "es-es" })) {
    if (-not (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "Office 365" })) {
        Write-Host "Installing Office 365..."`n
        Start-Process -FilePath "$PSScriptRoot\install\Office365\setup.exe" -ArgumentList /configure,"$PSScriptRoot\install\Office365\Office365BusinessRetail.xml" -WindowStyle Hidden -Wait
        if (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "Office 365" }) {
            Write-Host "Office 365 installation complete."`n
        } else {
            Write-Host "Office 365 installation failed."
            Write-Host "Please review logs at $env:TEMP\OfficeInstallLogs"`n
        }
    }
}

# Delete Edge shortcut from desktop
Remove-Item "$env:USERPROFILE\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue

# Install Chrome
if (-not (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*" | Where { $_.PSChildName -match "chrome" })) {
    Write-Host "Installing Google Chrome..."`n
    (New-Object System.Net.WebClient).DownloadFile("http://dl.google.com/chrome/install/375.126/chrome_installer.exe", "$env:TEMP\ChromeSetup.exe")
    Start-Process -FilePath "$env:TEMP\ChromeSetup.exe" -ArgumentList /silent, /install -Wait
    Write-Host "Google Chrome installation complete."`n
}

# Install Adober Reader
if (-not (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*" | Where { $_.PSChildName -match "AcroRd32" })) {
    Write-Host "Installing Adober Reader..."`n
    (New-Object System.Net.WebClient).DownloadFile("http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/2000920063/AcroRdrDC2000920063_en_US.exe", "$env:TEMP\AdobeReaderSetup.exe")
    Start-Process -FilePath "$env:TEMP\AdobeReaderSetup.exe" -ArgumentList /sPB -Wait
    Write-Host "Adobe Reader installation complete."`n
}

# End prompt
Write-Host "Done! Don't forget to set default apps, clean up task bar, and install tools."`n
For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]174)}
[console]::Beep();[console]::Beep()
Start-Sleep 3
For ($i=1; $i -le 18; $i++) {(New-Object -ComObject WScript.Shell).SendKeys([char]175)}
Read-Host -Prompt "Press Enter to exit"

# Add 415 Group local admin
if (-not (Get-LocalUser 415Admin -ErrorAction SilentlyContinue)) {
    Write-Host "Creating 415Admin user..."`n
    net user 415Admin * /add 
    net localgroup Administrators 415Admin /add
    wmic useraccount WHERE "Name='415Admin'" set PasswordExpires=false
    Write-Host "415Admin local admin created."`n
} else {
    Write-Host "Create a password for 415Admin user..."`n
   net user 415Admin *
    Write-Host "Password added."`n
}

if ($env:USERNAME -ne "415Admin") {

# Set default apps
$DefaultAppXML = @'
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".3g2" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".3gp" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".3gp2" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".3gpp" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".3mf" ProgId="AppXr0rz9yckydawgnrx5df1t9s57ne60yhn" ApplicationName="Print 3D" />
  <Association Identifier=".aac" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".ac3" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".adt" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".adts" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".amr" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".arw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".avi" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".bmp" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".cr2" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".crw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".dib" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".ec3" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".erf" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".fbx" ProgId="AppXmgw6pxxs62rbgfp9petmdyb4fx7rnd4k" ApplicationName="3D Viewer" />
  <Association Identifier=".flac" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".gif" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".glb" ProgId="AppXmgw6pxxs62rbgfp9petmdyb4fx7rnd4k" ApplicationName="3D Viewer" />
  <Association Identifier=".gltf" ProgId="AppXmgw6pxxs62rbgfp9petmdyb4fx7rnd4k" ApplicationName="3D Viewer" />
  <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".jfif" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".jpe" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".jpeg" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".jpg" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".jxr" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".kdc" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".m2t" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".m2ts" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".m3u" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".m4a" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".m4r" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".m4v" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mka" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".mkv" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mod" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mov" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".MP2" ProgId="WMP11.AssocFile.MP3" ApplicationName="Windows Media Player" />
  <Association Identifier=".mp3" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".mp4" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mp4v" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mpa" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".MPE" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mpeg" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mpg" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mpv2" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".mrw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".mts" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".nef" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".nrw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".obj" ProgId="AppXmgw6pxxs62rbgfp9petmdyb4fx7rnd4k" ApplicationName="3D Viewer" />
  <Association Identifier=".oga" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".ogg" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".ogm" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".ogv" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".ogx" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".opus" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".orf" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".pdf" ProgId="AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723" ApplicationName="Microsoft Edge" />
  <Association Identifier=".pef" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".ply" ProgId="AppXmgw6pxxs62rbgfp9petmdyb4fx7rnd4k" ApplicationName="3D Viewer" />
  <Association Identifier=".png" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".raf" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".raw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".rw2" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".rwl" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".sr2" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".srw" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".stl" ProgId="AppXr0rz9yckydawgnrx5df1t9s57ne60yhn" ApplicationName="Print 3D" />
  <Association Identifier=".tif" ProgId="PhotoViewer.FileAssoc.Tiff" ApplicationName="Windows Photo Viewer" />
  <Association Identifier=".tiff" ProgId="PhotoViewer.FileAssoc.Tiff" ApplicationName="Windows Photo Viewer" />
  <Association Identifier=".tod" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".TS" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".TTS" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".txt" ProgId="txtfile" ApplicationName="Notepad" />
  <Association Identifier=".url" ProgId="IE.AssocFile.URL" ApplicationName="Internet Browser" />
  <Association Identifier=".wav" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".wdp" ProgId="AppX43hnxtbyyps62jhe9sqpdzxn1790zetc" ApplicationName="Photos" />
  <Association Identifier=".webm" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".website" ProgId="IE.AssocFile.WEBSITE" ApplicationName="Internet Explorer" />
  <Association Identifier=".wm" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".wma" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".wmv" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".WPL" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier=".xvid" ProgId="AppX6eg8h5sxqq90pv53845wmnbewywdqq5h" ApplicationName="Movies &amp; TV" />
  <Association Identifier=".zpl" ProgId="AppXqj98qxeaynz6dv4459ayz6bnqxbyaqcs" ApplicationName="Groove Music" />
  <Association Identifier="bingmaps" ProgId="AppXp9gkwccvk6fa6yyfq3tmsk8ws2nprk1p" ApplicationName="Maps" />
  <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="mailto" ProgId="Outlook.URL.mailto.15" ApplicationName="Outlook" />
  <Association Identifier="microsoft-edge" ProgId="AppX7rm9drdg8sk7vqndwj3sdjw11x96jc0y" ApplicationName="Microsoft Edge" />
  <Association Identifier="microsoft-edge-holographic" ProgId="AppX3xxs313wwkfjhythsb8q46xdsq8d2cvv" ApplicationName="Microsoft Edge" />
  <Association Identifier="ms-xbl-3d8b930f" ProgId="AppXdn5b0j699ka5fqvrr3pgjad0evqarm6d" ApplicationName="Microsoft Edge" />
  <Association Identifier="mswindowsmusic" ProgId="AppXtggqqtcfspt6ks3fjzyfppwc05yxwtwy" ApplicationName="Groove Music" />
  <Association Identifier="mswindowsvideo" ProgId="AppX6w6n4f8xch1s3vzwf3af6bfe88qhxbza" ApplicationName="Movies &amp; TV" />
</DefaultAssociations>
'@
$DefaultAppXML > $env:TEMP\appdefaults.xml
Start-Process -FilePath "dism.exe" -ArgumentList "/Online, /Import-DefaultAppAssociations:$env:TEMP\appdefaults.xml"

# Open Windows to set default apps and install agents
Start-Process ms-settings:defaultapps
Start-Process $PSScriptRoot\installTools
New-Item -Path $env:TEMP -Name test.pdf -Force
(((New-Object -com Shell.Application).NameSpace("$env:TEMP")).ParseName("test.pdf")).InvokeVerb("Properties")
}

# Cleanup
#$ScriptPath = -join ("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\", $MyInvocation.MyCommand.Name)
Remove-Item $StartupScript -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\ChromeSetup.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\AdobeReaderSetup.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\test.pdf" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\appdefaults.xml" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\new-pc-setup.zip" -Force -ErrorAction SilentlyContinue

# Re-enable UAC
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 1 -Force | Out-Null

Stop-Transcript