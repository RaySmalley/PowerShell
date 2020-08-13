# Get volumes that need Shadow Copies
$volumes = Get-WmiObject win32_diskdrive | ?{$_.mediatype -eq "Fixed hard disk media"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} | %{Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} | Where {$_.VolumeName -ne "Recovery" -and $_.Size -ge 32212254720} | %{$_.deviceid}

# Check if Veeam installed
$veeam = (Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Veeam Backup & Replication*" })

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
        Continue
    }

    # Setup task variables
    $taskName = "ShadowCopyVolume" + $deviceID
    $XMLfile = "$env:TEMP\${taskName}.xml"
   
    # Delete existing Shadow Copy tasks (does not delete existing Shadow Copies)
    if (Test-Path C:\Windows\Tasks\${taskName}.job) {
        Write-Host "Deleting old Shadow Copy task for volume $volume - $taskName..."
        schtasks /delete /tn $taskName /f
        Write-Host ""
    }

    # Save XML contents to variable
    $XML = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.1" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>SYSTEM</Author>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <Enabled>true</Enabled>
      <StartBoundary>2016-01-04T12:15:00</StartBoundary>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Settings>
    <Enabled>true</Enabled>
    <ExecutionTimeLimit>P3D</ExecutionTimeLimit>
    <Hidden>false</Hidden>
    <WakeToRun>false</WakeToRun>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <Priority>5</Priority>
    <IdleSettings>
      <Duration>PT10M</Duration>
      <WaitTimeout>PT1H</WaitTimeout>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
  </Settings>
  <Principals>
    <Principal id="Author">
      <UserId>System</UserId>
      <RunLevel>HighestAvailable</RunLevel>
      <LogonType>InteractiveTokenOrPassword</LogonType>
    </Principal>
  </Principals>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\system32\vssadmin.exe</Command>
      <Arguments>Create Shadow /AutoRetry=15 /For=\\?\Volume123456789\</Arguments>
      <WorkingDirectory>%systemroot%\system32</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
'@
    
    # Insert volume's DeviceID
    $XML = $XML.replace("123456789","$deviceID")

    # Create XML file
    $XML > $XMLfile

    # Remove any empty lines in the XML file
    (Get-Content $XMLfile) | ? { $_.trim() -ne "" } | Set-Content $XMLfile

    # Import into Task Scheduler
    Write-Host "Creating new Shadow Copy task..."
    schtasks /create /xml $XMLfile /tn $taskName
    Sleep 5
    Write-Host ""

    # Ensure Shadow Copy max size is 10% of volume capacity
    $maxSize = [math]::Round($volumeInfo.Size / 10MB)
    Write-Host "Setting Shadow Copy max size for volume $volume to $maxSize (10%)..."
    vssadmin Resize ShadowStorage /On=$volume /For=$volume /MaxSize=${maxSize}MB
}