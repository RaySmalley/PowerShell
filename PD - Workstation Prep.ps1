$localuser = '415group'
$localpass = '7bFN$L=x>Mn35!'
#$newname = '@NewComputerName@'

$mspname = '415 Group'
$destdir = "$env:SystemRoot\Temp"
$serialNumber = Get-CimInstance Win32_bios | Select-Object -ExpandProperty serialnumber
$newname = $serialNumber

$oeminfo = @{
    'name' = $mspname
    'logo' = ''
    'supporthours' = ''
    'supportphone' = ''
    'supporturl' = ''
}
$screensaver = @{
    'timeoutsec' = 900
    'lockout' = 1
}
$actions = @{
    'LocalAdmin' = $false
    'DisableAdministrator' = $true
    'DeleteLocalUsers' = $false
    'EnableRDP' = $false
    'Firewall' = $false
    'DisableUAC' = $false
    'WindowsBloat' = $true
    'CleanStart' = $true
    'DisableCortana' = $true
    'DisablePeople' = $true
    'ScreenSaver' = $false
    'PowerPolicy' = $true
    'DisableNICPowerMgt' = $true
    'DisableHibernate' = $true
    'TimeZone' = 'Auto'
    'WinRM' = $false
    'AuditFilter' = $false
    'OEMInfo' = $false
    'NetFX35' = $false
    'DisableCE' = $true
    'SetDefaults' = $true
    'enableWOL' = $true
    'removeHPBloat' = $true
    'dcuUpdate' = $true
    'systemrestore' = $true
}
$installers = @(
    @{'Install'=$true;'Name'='Connect2Help';'Arch'='x64';'Source'='https://picondesigns.s3-us-west-1.amazonaws.com/Clients/415+group/';'Destination'="$destdir\Connect2Help";'Filename'='415GroupTrayMonitor.msi';Arguments='/qn'}
    @{'Install'=$true;'Name'='Connect2Help';'Arch'='x32';'Source'='https://picondesigns.s3-us-west-1.amazonaws.com/Clients/415+group/';'Destination'="$destdir\Connect2Help";'Filename'='415GroupTrayMonitor.msi';Arguments='/qn'}
    @{'Install'=$true;'Name'='Webroot';'Arch'='x64';'Source'='https://anywhere.webrootcloudav.com/zerol/';'Destination'="$destdir\Webroot";'Filename'='wsasme.exe';Arguments="/key=$keycode /silent"}
    @{'Install'=$true;'Name'='Webroot';'Arch'='x32';'Source'='https://anywhere.webrootcloudav.com/zerol/';'Destination'="$destdir\Webroot";'Filename'='wsasme.exe';Arguments="/key=$keycode /silent"}
    @{'Install'=$true;'Name'='Google Chrome';'Arch'='x64';'Source'='https://picondesigns.s3-us-west-1.amazonaws.com/Software/Google';'Destination'="$destdir\Google";'Filename'='GoogleChromeStandaloneEnterprise.msi';'Arguments'='/qn'}
    @{'Install'=$true;'Name'='Google Chrome';'Arch'='x86';'Source'='https://picondesigns.s3-us-west-1.amazonaws.com/Software/Google';'Destination'="$destdir\Google";'Filename'='GoogleChromeStandaloneEnterprise.msi';'Arguments'='/qn'}
    @{'Install'=$false;'Name'='Notepad ++';'Arch'='x64';'Source'='https://s3.console.aws.amazon.com/s3/object/picondesigns/Software/Notepad%252B%252B';'Destination'="$destdir\Notepad++";'Filename'='npp785Installer-x64.exe';'Arguments'='/S'}
    @{'Install'=$false;'Name'='Notepad ++';'Arch'='x86';'Source'='https://s3.console.aws.amazon.com/s3/object/picondesigns/Software/Notepad%252B%252B';'Destination'="$destdir\Notepad++";'Filename'='npp785Installer.exe';'Arguments'='/S'}
    @{'Install'=$true;'Name'='Adobe Acrobat Reader DC';'Arch'='*';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Adobe+Reader';'Destination'="$destdir\Adobe";'Filename'='AcroRdrDC1901020099_en_US.exe';'Arguments'='/sAll /msi EULA_ACCEPT=YES /qn'}
    @{'Install'=$false;'Name'='Amazon Corretto (x64)';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Corretto';'Destination'="$destdir\Corretto";'Filename'='amazon-corretto-8.212.04.2-windows-x64.msi';'Arguments'="/qn"}
    @{'Install'=$false;'Name'='Amazon Corretto';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Corretto';'Destination'="$destdir\Corretto";'Filename'='amazon-corretto-8.212.04.2-windows-x86.msi';'Arguments'="/qn"}
    @{'Install'=$false;'Name'='7-Zip';'Arch'='x64';'Source'='https://www.7-zip.org/a';'Destination'="$destdir\7Zip";'Filename'='7z1900-x64.msi';'Arguments'="/qn"}
    @{'Install'=$False;'Name'='7-Zip';'Arch'='x86';'Source'='https://www.7-zip.org/a';'Destination'="$destdir\7zip";'Filename'='7z1900.msi';'Arguments'="/qn"}
    @{'Install'=$false;'Name'='Silverlight';'Arch'='*';'Source'='https://picondesigns.s3-us-west-1.amazonaws.com/Software/Microsoft/Silverlight';'Destination'="$destdir\Silverlight";'Filename'='Silverlight.exe';'Arguments'="/s"}
    @{'Install'=$false;'Name'='Adobe AIR';'Arch'='*';'Source'='https://airdownload.adobe.com/air/win/download/32.0';'Destination'="$destdir\AdobeAir";'Filename'='AdobeAIRInstaller.exe';'Arguments'="/s"}
    @{'Install'=$true;'Name'='Mozilla Firefox';'Arch'='x64';'Source'='https://picondesigns.s3-us-west-1.amazonaws.com/Software/Mozilla';'Destination'="$destdir\Firefox";'Filename'='FirefoxSetup75.0b8x64.msi';'Arguments'="/qn"}
    @{'Install'=$true;'Name'='Mozilla Firefox';'Arch'='x86';'Source'='https://picondesigns.s3-us-west-1.amazonaws.com/Software/Mozilla';'Destination'="$destdir\Firefox";'Filename'='FirefoxSetup75.0b8x86.msi';'Arguments'="/qn"}    
    @{'Install'=$false;'Name'='Microsoft Visual C++ 2005 Redistributable (x64)';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2005';'Destination'="$destdir\MVC";'Filename'='vcredist_x64.exe';'Arguments'="/q"}
    @{'Install'=$false;'Name'='Microsoft Visual C++ 2005 Redistributable';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2005';'Destination'="$destdir\MVC";'Filename'='vcredist_x86.exe';'Arguments'="/q"}
    @{'Install'=$false;'Name'='Microsoft Visual C++ 2008 Redistributable - x64 9.0.21022';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2008';'Destination'="$destdir\MVC";'Filename'='vcredist_x64.exe';'Arguments'="/q"}
    @{'Install'=$false;'Name'='Microsoft Visual C++ 2008 Redistributable';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2008';'Destination'="$destdir\MVC";'Filename'='vcredist_x86.exe';'Arguments'="/q"}
    @{'Install'=$false;'Name'='Microsoft Visual C++ 2010 x64 Redistributable - 10.0.30319';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2010';'Destination'="$destdir\MVC";'Filename'='vcredist_x64.exe';'Arguments'="/q"}
    @{'Install'=$false;'Name'='Microsoft Visual C++ 2010 Redistributable';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2010';'Destination'="$destdir\MVC";'Filename'='vcredist_x86.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2012 Redistributable (x64) - 11.0.60610';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2012';'Destination'="$destdir\MVC";'Filename'='vcredist_x64.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2012 Redistributable';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2012';'Destination'="$destdir\MVC";'Filename'='vcredist_x86.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2013 Redistributable (x64) - 12.0.30501';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2013';'Destination'="$destdir\MVC";'Filename'='vcredist_x64.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2013 Redistributable';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2013';'Destination'="$destdir\MVC";'Filename'='vcredist_x86.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2015 Redistributable';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2015';'Destination'="$destdir\MVC";'Filename'='vc_redist.x64.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2015 Redistributable';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2015';'Destination'="$destdir\MVC";'Filename'='vc_redist.x86.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2017 Redistributable (x64) - 14.11.25325';'Arch'='x64';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2017';'Destination'="$destdir\MVC";'Filename'='VC_redist.x64.exe';'Arguments'="/q"}
    @{'Install'=$true;'Name'='Microsoft Visual C++ 2017 Redistributable';'Arch'='x86';'Source'='https://s3-us-west-1.amazonaws.com/picondesigns/Software/Microsoft/MVC/MVC2017';'Destination'="$destdir\MVC";'Filename'='vc_redist.x86.exe';'Arguments'="/q"}
)
$bloatapps = @('king.com*','king.com.CandyCrushSaga','*3dbuild*','Microsoft.Office.Desktop','Microsoft.MicrosoftOfficeHub','*SkypeApp*','*getstarted*','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.BingFinance','Microsoft.BingNews','Microsoft.BingSports','Microsoft.BingWeather','Microsoft.XboxApp','*SolitaireCollection*','*Netflix','Facebook.Facebook','*MarchofEmpires','*Twitter*','flaregamesGmbH.RoyalRevolt2','*Spotify*')


$syslog = "$destdir\WkstPrep.log"
$sysTime = Get-Date
if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { $arch = 'x64' } else { $arch = 'x86' }

function sysLog {
    Param (
        [Parameter(Mandatory = $true)]$message,
        [Parameter(Mandatory = $true)]$category,
        [Parameter(Mandatory = $false)]$display = $false
    )
    $sysLogName = "Workstation Prep Script"
    switch ($category) {
        'ERROR' { $etype = 1; break}
        'WARN' { $etype = 2; break}
        default { $etype = 4; break}
    }
    If (-not([System.Diagnostics.EventLog]::SourceExists($sysLogName))) { New-EventLog -LogName Application -Source $sysLogName }
    Write-EventLog -Message $message -LogName Application -Source $sysLogName -EntryType $etype -EventId 1001 -Category 0
    $string = "["+(Get-Date -Format g)+"] " + "[$category] $message"
    if($display -eq $true) {write-host $message}
    Return
}
function sysDownload {
    Param (
        [Parameter(Mandatory = $true)]$source,
        [Parameter(Mandatory = $true)]$destdir,
        [Parameter(Mandatory = $true)]$filename
    )
    If (-not(Test-Path -Path $destdir -PathType Container)) {
        sysLog -category "INFO" -message "Destination directory $destdir does not exist, creating it now." -display $true
        Try {
            New-Item -Path $destdir -ItemType Directory | Out-Null
        } Catch {
            sysLog -category "ERROR" -message "Failed to create the directory $destdir due to the following error: $($_.Exception.Message)." -display $true
            return $false
        }
    } else {
        sysLog -category "INFO" -message "The destination directory already exists, removing any previously downloaded version."
        Remove-Item -Path "$destdir\$filename" -Force -ErrorAction SilentlyContinue
    }
    sysLog -category "INFO" -message "Downloading $filename from $source and saving to $destdir." -display $true
    $webclient = New-Object System.Net.WebClient
    $return = $true
    Try {
        $webclient.DownloadFile("$source/$filename","$destdir\$filename")
    } Catch {
        sysLog -category 'ERROR' -message "Failed to download $filename from $source due to the following error: $($_.Exception.Message)." -display $true
        $return = $false
    }
    return $return
}
function sysRun {
    Param (
        [Parameter(Mandatory = $true)]$filename,
        [Parameter(Mandatory = $true)]$arguments
    )
    If (Test-Path -Path $filename) {
        sysLog -category "INFO" -message "Preparing to run $filename with arguments $arguments." -display $true
        If ($filename.IndexOf(".msi") -ge 0) {
            $switches = "/i $filename $arguments"
            $execute = "msiexec.exe"
        } else {
            $switches = $arguments
            $execute = $filename
        }
        sysLog -category "INFO" -message "Executing the command $execute with the following switches $switches." -display $true
        Start-Process -FilePath $execute -ArgumentList $switches -Wait
        sysLog -category "INFO" -message "Finishing executing command $execute." -display $true
    } else {
        sysLog -category "ERROR" -message "The file $filename cannot be found." -display $true
    }
}
function checkInstalled {
    Param (
        [Parameter(Mandatory = $true)]$software
    )
    sysLog -category "INFO" -message "Checking if the software $software is installed on this computer." -display $true
    $installed = $false
    $installed64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, UninstallString, PSChildName | Where-Object {$_.DisplayName -like "$software*"}
    $installed32 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, UninstallString, PSChildName | Where-Object {$_.DisplayName -like "$software*"}
    sysLog -category "INFO" -message "Result64: $($installed64.UninstallString)." -display $false
    sysLog -category "INFO" -message "Result32: $($installed32.UninstallString)." -display $false
    If ($installed64.UninstallString) { $installed = $true }
    If ($installed32.UninstallString) { $installed = $true }
    sysLog -category "INFO" -message "The software $software found on the computer: $installed" -display $true
    return $installed
}
function userHives {
    param ( 
        [Parameter(Mandatory=$true)]$regkey,
        [Parameter(Mandatory=$true)]$regname,
        [Parameter(Mandatory=$true)]$regval
    )
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
    $profileList = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $profileFolder = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').ProfilesDirectory
    $temphive = "HKU\UserHive"

    foreach ($profile in $profileList) {
        $proProps = Get-ItemProperty $profile.PSPath
        $sid = $proProps.PSChildName

        $profileHive = "HKU:\$sid"
        $loaded = $true
        If (!(Get-ChildItem "HKU:\$sid" -ErrorAction SilentlyContinue)) {
            Write-Host "The profile with SID $sid is not loaded in the registry."
            $profileHive = $temphive
            $loaded = $false
            $oldErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "stop"
            Try {
                Write-Host "Trying to load registry hive $($($proProps.ProfileImagePath))"
                $void = REG LOAD $temphive "$($proProps.ProfileImagePath)"
            } Catch {
                Write-Host "Failed to load the registry $($proProps.ProfileImagePath) due to $($_.Exception.Message)."
                break
            } Finally {
                $error.Clear()
                $ErrorActionPreference = $oldErrorActionPreference
            }
        }
        Write-Host "The registry hive for user $sid loaded successfully."
        If (Test-Path -Path "$profileHive\$regkey") {
            $existing = Get-ItemProperty -Path "$profileHive\$regkey" -Name $RegName -ErrorAction SilentlyContinue
            If ($existing) {
                Write-Host "Registry value exists already, resetting to new value."
                $void = Set-ItemProperty -Path "$profileHive\$regkey" -Name $RegName -Value $RegVal -Force | Out-Null
            } else {
                Write-Host "Registry value does not exist, adding value."
                $void = New-ItemProperty -Path "$profileHive\$regkey" -Name $RegName -Value $RegVal -PropertyType String -Force | Out-Null
            }
        } else {
            Write-Host "The registry key $profileHive\$regkey doesn't exist, the script will attempt to create the key and property."
            New-Item "$profileHive\$regkey" -Force | New-ItemProperty -Name $RegName -Value $RegVal -PropertyType String | Out-Null
        }
        If (!($loaded)) {
            $void = REG UNLOAD $temphive
        }
    }
    Remove-PSDrive -Name HKU
}

function localAdmin {
    Param (
        [Parameter(Mandatory = $true)]$username,
        [Parameter(Mandatory = $true)]$password,
        [Parameter(Mandatory = $true)]$group
    )
    sysLog -category 'INFO' -message "Creating or updating local administrative account $username." -display $true
    $disabled = 0x0002
    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $exists = $adsi.Children | Where {$_.SchemaClassName -eq "user" -and $_.Name -eq $username}
    $gadsi = [ADSI]"WinNT://$env:COMPUTERNAME/$group"
    $gmbrsObj = @($gadsi.psbase.Invoke("Members")) 
    $gmbrs = ($gmbrsObj | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})

    if ($exists) {
        sysLog -category 'INFO' -message "The username $username already exists, setting account password and settings." -display $true
        if ($exists.UserFlags.value -BAND 2) {$exists.userflags.value = $exists.UserFlags.value -BXOR 2}
        $exists.userflags.value = $exists.userflags.value -BOR 65536
        $exists.SetPassword($password)
        $exists.SetInfo()
        if ($gmbrs -notcontains $username) {
            $gadsi.add("WinNT://$env:COMPUTERNAME/$username")
            $gadsi.SetInfo()
        }
    } else {
        sysLog -category 'INFO' -message "The username $username does not exists and will be created." -display $true
        $user = $adsi.Create("user",$username)
        $user.SetPassword($password)
        $user.SetInfo()
        $gadsi.add("WinNT://$env:COMPUTERNAME/$username")
        $gadsi.SetInfo()
    }
}
function disableAdministrator {
    sysLog -category 'INFO' -message "Disabling local administrator user account." -display $true
    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME/Administrator,user"
    If ($adsi.Guid) {
        If ($adsi.AccountDisabled -eq $False) {
            sysLog -category 'INFO' -message "Local administrator account exists and is not disabled, setting disabled flag." -display $false
            $adsi.AccountDisabled = $True
            $adsi.SetInfo()
        } else {
            sysLog -category 'INFO' -message "Local administrator account exists and but is already disabled." -display $false
        }
    } else {
        sysLog -category 'INFO' -message "Local administrator account does not exist." -display $true
    }
}
function deleteLocalUsers {
    sysLog -category 'INFO' -message "Removing all local user accounts from the system." -display $true
    $omit = @('DefaultAccount',$localUser)
    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $adsiUsers = $adsi.Children | Where-Object {($_.SchemaClassName  -eq 'user') -and ($_.Name -notin $omit)}
    sysLog -category 'INFO' -message "Found $($adsiUsers.Count) local user accounts." -display $true
    $adsiUsers | % {
        If ($_.Guid) {
            sysLog -category 'INFO' -message "Deleting local user account $($_.Name)." -display $true
            Try {
                $adsi.Delete('User',"$($_.Name)")
            } Catch {
                sysLog -category 'ERROR' -message "Failed to delete user account $($_.Name) due to the following: $($_.Exception.Message)" -display $true
            }
        }
    }
}
function Windows10Bloat {
    sysLog -category 'INFO' -message "Starting Windows 10 Bloatware Removal." -display $true
    foreach ($app in $bloatapps) {
        sysLog -category 'INFO' -message "Removing Windows 10 App $app." -display $true
        Try {
            Get-AppxPackage -AllUsers $app | Remove-AppxPackage -AllUsers
            Get-ProvisionedAppxPackage -Online | Where {$_.DisplayName -like $app} | Remove-ProvisionedAppxPackage -Online -AllUsers
        } Catch {
            sysLog -category 'INFO' -message "Failed to remove AppX Package for $app with error $($_.Exception.Message)" -display $true
        }
    }
}
function PowerPolicy {
    sysLog -category 'INFO' -message "Setting Power Policy to Always On." -display $true
    $pwrschemes = &powercfg.exe /LIST
    foreach ($pwrscheme in $pwrschemes) {
        If ($pwrscheme -like '*(High performance)*') {
            $guid = $pwrscheme.substring(19,36)
            Start-Process -FilePath 'powercfg.exe' -ArgumentList "/SETACTIVE $guid"
        }
    }
    sysLog -category 'INFO' -message "Setting Monitor Timeout to 30 Minutes." -display $true
    Start-Process -FilePath 'powercfg.exe' -ArgumentList '/change -monitor-timeout-ac 30' -Wait -NoNewWindow
    Start-Process -FilePath 'powercfg.exe' -ArgumentList '/change -monitor-timeout-dc 30' -Wait -NoNewWindow
}
function DisableNICPowerMgt {
    sysLog -category 'INFO' -message "Setting Physical Network Adapter Power Settings." -display $true
    $adapters = Get-NetAdapter -Physical | Get-NetAdapterPowerManagement
    foreach ($adapter in $adapters) {
        Write-Host "Setting Power Management Settings for $($adapter.InterfaceDescription)."
        $adapter.AllowComputerToTurnOffDevice = 'Disabled'
        If ($adapter.WakeOnMagicPacket -ne 'Unsupported') { $adapter.WakeOnMagicPacket = 'Enabled' }
        $adapter | Set-NetAdapterPowerManagement
    }
}
function NoHibernate {
    sysLog -category 'INFO' -message "Disabling hibernate option." -display $true
    Start-Process -FilePath 'powercfg.exe' -ArgumentList '/hibernate off'
}
function setTimeZone {
    sysLog -category "INFO" -message "Setting system time zone to $($sctions.TimeZone)." -display $true
    If ($sctions.TimeZone -eq 'Auto') {
        sysLog -category "INFO" -message "Setting system to auto-update Time Zone by location." -display $true
        Try {
            Set-ItemProperty -Path 'HKLM:SYSTEM\CurrentControlSet\Services\tzautoupdate' -Name 'Start' -Value 3
        } Catch {
            sysLog -category "ERROR" -message "Failed to set the auto-update time zone service due to error $($_.Exception.Message)." -display $true
        }
    } else {
        Try {
            Set-TimeZone $sctions.TimeZone
        } Catch {
            sysLog -category "ERROR" -message "Failed to set the system time zone to $setTimeZone due to error $($_.Exception.Message)." -display $true
        }
    }
}
function enableWinRM {
    sysLog -category "INFO" -message "Enabling WinRM Remote Management." -display $true
    Enable-PSRemoting -Force -ErrorAction SilentlyContinue
    Set-Service WinRM -StartMode Automatic
    Start-Service WinRM
}
function enableRDP {
    sysLog -category 'INFO' -message "Enabling Remote Desktop Connection." -display $true
    $regkey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $regname = "fDenyTSConnections"
    $regval = 0
    Try {
        Set-ItemProperty -Path $regkey -Name $regname -Value $regval
    } Catch {
        sysLog -category 'ERROR' -message "Failed to enabled RDP due to $($_.Exception.Message)." -display $true
    }
}
function setFirewall {
    sysLog -category 'INFO' -message "Deactivating Windows Firewall for Domain and Private Networks." -display $true
    Try {
        Set-NetFirewallProfile -Name Domain,Private -Enabled False
    } Catch {
        sysLog -category "ERROR" -message "Failed to set Windows Firewall status due to error: $($_.Exception.Message)." -display $true
    }
}
function enableAudits {
    sysLog -category "INFO" -message "Enabling Logon and Logoff Security Auditing."  -display $true
    Start-Process -FilePath "auditpol.exe" -ArgumentList '/set /category:"Logon/Logoff" /success:enable /failure:enable'
}
function disableUAC {
    sysLog -category "INFO" -message "Disabling UAC Settings."  -display $true
    Try {
        Set-ItemProperty -Path 'HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system' -Name 'EnableLUA' -Value 0
    } Catch {
        sysLog -category "ERROR" -message "Failed to set the auto-update time zone service due to error $($_.ErrorMessage)." -display $true
    }
}
function disableAdminFilter {
    sysLog -category "INFO" -message "Disabling Administrator Account Filtering."  -display $true
    Try {
        Set-ItemProperty -Path 'HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system' -Name 'FilterAdministratorToken' -Value 1
    } Catch {
        sysLog -category "ERROR" -message "Failed to set the auto-update time zone service due to error $($_.ErrorMessage)." -display $true
    }
}
function userDefaults {
    sysLog -category "INFO" -message "Performing user default registry changes." -display $true
    $hku = Get-PSDrive | Where-Object {$_.Root -eq 'HKEY_USERS'}
    If (!($hku)) { New-PSDrive -Name 'HKU' -PSProvider Registry -Root "HKEY_USERS" }
    $regitems = @(
        @{'Name'='Disable Live Tiles'; 'Key'='HKU:\.DEFAULT\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'; 'Property'='NoTileApplicationNotification'; 'Val'=1; 'Type'='DWORD'}
        @{'Name'='Disable People Icon'; 'Key'='HKU:\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'; 'Property'='PeopleBand'; 'Val'=0; 'Type'='DWORD'}
        @{'Name'='Disable Start Menu Suggestions'; 'Key'='HKU:\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; 'Property'='SystemPaneSuggestionsEnabled'; 'Val'=0; 'Type'='DWORD'}
        @{'Name'='Disable Windows Feedback Experience'; 'Key'='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; 'Property'='Enabled'; 'Val'=0; 'Type'='DWORD'}
        @{'Name'='Disable Start Menu Cortana'; 'Key'='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; 'Property'='AllowCortana'; 'Val'=0; 'Type'='DWORD'}
    )
    foreach ($regitem in $regitems) {
        sysLog -category "INFO" -message "Processing registry change for $($regitem.Name)." -display $true
        $test = Get-ItemProperty -Path $regitem.Key -Name $regitem.Property -ErrorAction SilentlyContinue
        If ($test) {
            sysLog -category "INFO" -message "Setting $($regitem.Property) value to ($($regitem.Val) in key $($regitem.Key)" -display $false
            Set-ItemProperty -Path $regitem.Key -Name $regitem.Property -Value $regitem.Val
        } else {
            sysLog -category "INFO" -message "Adding $($regitem.Property) value ($($regitem.Val) in key $($regitem.Key)" -display $false
            New-ItemProperty -Path $regitem.Key -Name $regitem.Property -Value $regitem.Val -PropertyType $regitem.Type
        }
    }
    Remove-PSDrive -Name 'HKU'
}
function setOEMInfo {
    sysLog -category "INFO" -message "Setting System Properties OEM Information."  -display $true
    $regkey = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
    If ($oeminfo.logo) {
        sysDownload -source 'https://picondesigns.s3-us-west-1.amazonaws.com/Clients/Logos' -destdir $destdir -filename $oeminfo.logo
        Set-ItemProperty -Path $regkey -Name 'Logo' -Value "$destdir\$($oeminfo.logo)" -Force
    }
    If ($oeminfo.name) { Set-ItemProperty -Path $regkey -Name 'Manufacturer' -Value $oeminfo.name -Force }
    If ($oeminfo.supportphone) { Set-ItemProperty -Path $regkey -Name 'SupportPhone' -Value $oeminfo.supportphone -Force }
    If ($oeminfo.supporturl) { Set-ItemProperty -Path $regkey -Name 'SupportURL' -Value $oeminfo.supporturl -Force }
    If ($oeminfo.supporthours) { Set-ItemProperty -Path $regkey -Name 'SupportHours' -Value $oeminfo.supporthours -Force }
}
function cleanStart {
    sysLog -category "INFO" -message "Cleaning default start menu tiles layout."  -display $true
    $cleanXML='<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
      <StartLayoutCollection>
        <defaultlayout:StartLayout GroupCellWidth="6" />
      </StartLayoutCollection>
    </DefaultLayoutOverride>
  </LayoutModificationTemplate>'
    Set-Content -Path "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Value $cleanXML -Force
    sysLog -category 'INFO' -message "Removing Cortana from taskbar." -display $true
    userHives -regkey "SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -regname "SearchboxTaskbarMode" -regval 0
    sysLog -category 'INFO' -message "Removing People from taskbar." -display $true
    userHives -regkey "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -regname "PeopleBand" -regval 0
}
function installNetFX3 {
    sysLog -category "INFO" -message "Performing .NET Framework 3.5 Installation."  -display $true
    Start-Process -FilePath 'DISM' -ArgumentList '/online /enable-feature /featurename:NetFX3' | Out-Null
}
function ScreenSaver {
    sysLog -category "INFO" -message "Setting Screen Saver to enabled, with a $($screensaver.timeoutsec) second timeout and auto lock enabled set to $($screensaver.lockout)."  -display $true
    userHives -regkey 'Control Panel\Desktop' -regname 'ScreenSaveActive' -regval 1
    userHives -regkey 'Control Panel\Desktop' -regname 'ScreenSaverIsSecure' -regval $screensaver.lockout
    userHives -regkey 'Control Panel\Desktop' -regname 'ScreenSaveTimeOut' -regval $screensaver.timeoutsec
    userHives -regkey 'Control Panel\Desktop' -regname 'SCRNSAVE.EXE' -regval "$env:SystemRoot\system32\scrnsave.scr"
}
function setDefaults {
    sysLog -category 'INFO' -message "Setting Default File Associations and Applications." -display $true
    Invoke-webrequest -uri "https://picondesigns.s3-us-west-1.amazonaws.com/Tools/appdefaults.xml" -outfile "$destdir\appdefaults.xml"
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Import-DefaultAppAssociations:$destdir\appdefaults.xml"
}
function disableCortana {
    sysLog -category 'INFO' -message "Disabling Cortana Search." -display $true
    $regkey = "HKLM:SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $regname = "AllowCortana"
    $regval = 0
    If (-not(Test-Path -Path $regkey -ErrorAction SilentlyContinue)) { New-Item -Path 'HKLM:SOFTWARE\Policies\Microsoft\Windows' -Name 'Windows Search' -ItemType Container -Force | Out-Null}
    If (Get-ItemProperty -Path $regkey -Name $regname -ErrorAction SilentlyContinue) {
        Set-ItemProperty -Path $regkey -Name $regname -Value $regval -Force | Out-Null
    } else {
        New-ItemProperty -Path $regkey -Name $regname -Value $regval -PropertyType DWORD | Out-Null
    }
}
function disablePeople {
    sysLog -category 'INFO' -message "Disabling People Icon." -display $true
    userHives -regkey "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -regname 'PeopleBand' -regval 0 | Out-Null
}
function disableConsumerExperience {
    $regkey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    $regname = 'DisableWindowsConsumerFeatures'
    $regval = 1
    $regtype = 'DWORD'
    sysLog -category 'INFO' -message "Disabling Windows 10 Consumer Experience." -display $true
    If (Test-Path -Path $regkey -ErrorAction SilentlyContinue) {
        Set-ItemProperty -Path $regkey -Name $regname -Value $regval -Force | Out-Null
    } else {
        New-Item -path $regkey -ItemType Container | Out-Null
        New-ItemProperty -Path $regkey -Name $regname -Value $regval -PropertyType $regtype -Force | Out-Null
    }
}
# Remove HP Bloatware
function removeHPBloat {
    sysLog -category "INFO" -message "Removing HP Bloat" -display $true
    $hpbloat_url = "https://picondesigns.s3-us-west-1.amazonaws.com/LivePowerShell/Live-HPBloatwareUninstall.ps1"
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString($hpbloat_url)
}

#Dell Command Update
function dcuUpdate {
    sysLog -category 'INFO' -message "Downloading Dell Command Updating." -display $true
    sysDownload -source 'https://picondesigns.s3-us-west-1.amazonaws.com/Software/Dell/Command' -destdir "$destdir\DCU" -filename 'DCU.zip'
    
    Expand-Archive -Path "$destdir\DCU\DCU.Zip" -DestinationPath "$destdir\DCU" -Force
    try {
        sysLog -category 'INFO' -message "Executing Dell Command Update." -display $true
        sysRun -filename "$destdir\DCU\DCU\dcu-cli.exe" -arguments "/import /policy ""$destdir\DCU\DCU\MySettings.xml"""
        Start-Process -FilePath "$destdir\DCU\DCU\dcu-cli.exe" -Wait
    }
    catch {
        sysLog -category 'ERROR' -message "Dell Command Update failed due to $($_.Exception.Message)." -display $true
    }
}

#Enable WOL
function enableWOL {
    sysLog -category 'INFO' -message "Downloading and Executing Dell Wake on Lan Bios Update." -display $true
    $wol_url = "https://picondesigns.s3-us-west-1.amazonaws.com/LivePowerShell/Live-EnableDellWOLBiosSetting.ps1"
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString($wol_url)
}

sysLog -category 'INFO' -message "Starting workstation prep script at $sysTime." -display $true
sysLog -category 'INFO' -message "Log file can be found at $syslog." -display $true
sysLog -category 'INFO' -message "Found processor architecture $arch. with Serial Number $serialNumber" -display $true

foreach ($installer in $installers) {
    If ($installer.Install -and ($installer.Arch -eq $arch -or $installer.Arch -eq '*')) {
        sysLog -category 'INFO' -message "Starting installation of $($installer.Name)." -display $true
        If (-not(checkInstalled -software $installer.Name)) {
            $dl = sysDownload -source $installer.Source -destdir $installer.Destination -filename $installer.Filename
            If ($dl) {
                sysRun -filename "$($installer.Destination)\$($installer.Filename)" -arguments $installer.Arguments
                sysLog -category 'INFO' -message "Completed installation of $($installer.Name)." -display $true
            } else {
                sysLog -category 'ERROR' -message "Failed to install $($installer.Name)." -display $true
            }
        }
    }
}

#Create System Restore Point
function New-systemrestore {
    $type = "APPLICATION_INSTALL"
    $desc = "Daily Restore Point"
    $drv = $env:SystemDrive
    $osVersion = (Get-WmiObject -class Win32_OperatingSystem).Caption
    $points = Get-ComputerRestorePoint
    $old_restore_points = (Get-Date).AddDays(-14)
    if ($osVersion -cmatch "Microsoft Windows 10") {
	    If ($points)
	    {
		    Checkpoint-Computer -Description $desc -RestorePointType $type
		    if ($points.count -gt 2) {
                $points | Where-Object { $_.ConvertToDateTime($_.CreationTime) -lt $old_restore_points } | Delete-ComputerRestorePoint
                syslog -category "INFO" -message "System Restore Point Created"
                $restore_point = "Success"
            }
        }
        else {
            Try {
                syslog -category "INFO" -message "System Restore Point Created"
                Enable-ComputerRestore -Drive "$drv\"
            }
            Catch {
                syslog -category "ERROR" -message "Failed to enabled System Restore on the system."
                $restore_point = "Failed"
                break
		    }
        Checkpoint-Computer -Description $desc -RestorePointType $type
        syslog -category "INFO" -message "System Restore Point Created"
		$restore_point = "Success"
	}
	if ($osVersion -cmatch "Microsoft Windows 7") {
		$restore_point = "Success - No Restore Point Created, Windows 7"
	    }
    }
}

If ($actions.LocalAdmin) { localAdmin -username $localuser -password $localpass -group "Administrators" }
If ($actions.DisableAdministrator) { disableAdministrator }
If ($actions.DeleteLocalUsers) { deleteLocalUsers }
If ($actions.EnableRDP) { enableRDP }
If ($actions.Firewall) { setFirewall }
If ($actions.DisableUAC) { disableUAC }
If ($actions.WindowsBloat) { Windows10Bloat }
If ($actions.CleanStart) { cleanStart }
If ($actions.DisableCortana) { disableCortana }
If ($actions.DisablePeople) { disablePeople }
If ($actions.ScreenSaver) { ScreenSaver }
If ($actions.PowerPolicy) { PowerPolicy }
If ($actions.DisableHibernate) { NoHibernate }
If ($actions.TimeZone) { setTimeZone }
If ($actions.WinRM) { enableWinRM }
If ($actions.AuditFilter) { enableAudits }
If ($actions.OEMInfo) { setOEMInfo }
If ($actions.NetFX35) { installNetFX3 }
If ($actions.DisableCE) { disableConsumerExperience }
If ($actions.SetDefaults) { setDefaults }
If ($actions.enableWOL) { enableWOL}
If ($actions.removeHPBloat) { removeHPBloat}
If ($actions.dcuUpdate) {dcuUpdate}
If ($actions.DisableNICPowerMgt) { DisableNICPowerMgt }
if ($actions.systemrestore) {New-systemrestore}
If ($newname -and ($newname -ne $env:COMPUTERNAME)) {
    sysLog -category 'INFO' -message "Renaming computer to $newname." -display $true
    Rename-Computer -NewName $newname -Force | Out-Null
}

sysLog -category 'INFO' -message "Workstation prep script completed. A computer restart may be required to complete all of the changes." -display $true