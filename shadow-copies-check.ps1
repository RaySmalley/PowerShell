# Get volumes that need Shadow Copies
$volumes = Get-WmiObject win32_diskdrive | ?{$_.mediatype -eq "Fixed hard disk media"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | Where {$_.VolumeName -ne "Recovery" -and $_.Size -ge 32212254720} | %{$_.deviceid}

# Check if Veeam installed
$veeam = (Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Veeam Backup & Replication*" })

$volumesNoShadows = @()

# Loop through each volume
ForEach ($volume in $volumes) {

    # Setup variables for volume info queries
    $volumeWmi = Get-WmiObject Win32_Volume -Namespace root/cimv2 | ?{ $_.Name -eq "$volume" + "\" }
    $deviceID = $volumeWmi.DeviceID.ToUpper().Replace("\\?\VOLUME", "").Replace("\","")
    
    # If Veeam is installed, check if volume contains Veeam backups. Skip volume if so.
    if ($veeam) {
        if (-Not (Test-Path $volume\veeam_repository_volume)) {
            if (Get-ChildItem $volume\ -recurse -filter *.vbk -ErrorAction SilentlyContinue) {
                New-Item $volume\veeam_repository_volume -ItemType File
                Continue
            }
        } else {
            Continue
        }
    }

    # Check for at least 25% free space on volume; skip to next volume if less
    $volumeInfo = Get-WmiObject Win32_logicaldisk -Filter "deviceid='$volume'"
    $shadowData = (Get-WmiObject Win32_ShadowStorage | Where { $_.Volume -match $deviceID }).UsedSpace
    $percentFree = [math]::Round((($volumeInfo.FreeSpace + $shadowData) / $volumeInfo.Size) * 100)
    if ($percentFree -lt 25) {
        Write-Host Volume $volume has only $percentFree percent free space. Skipping...
        $message = "Only $percentFree% space left."
    } else { $message = "" }

    # Setup task variables
    $taskName = "ShadowCopyVolume" + $deviceID
    
    # Check to see if ShadowCopies is enabled for the volume
    if (-Not (Test-Path C:\Windows\Tasks\${taskName}.job)) {
        $volumesNoShadows += "Drive $volume does not have Shadow Copies enabled. $message "
    }
}

$OFS = "`r`n"
$status = $volumesNoShadows.Count
$volumesNoShadows = [string]$volumesNoShadows