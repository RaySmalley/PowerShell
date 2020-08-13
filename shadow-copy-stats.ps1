Param(
	$ServerName,
	[Int32]$TimeOut = 500,
	[switch]$ShowAllVolumes,
	[string]$From = "FSadmins@company.tld",
	[string]$To = "FSadmins@company.tld",
	[string]$SMTPServer = "smtp.company.tld",
	[string]$Subject = "Shadow Copy Stats.",
	[switch]$EmailLog
)
Begin
{	$script:CurrentErrorActionPreference = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"
	$Style = "<Style>BODY{font-size:12px;font-family:verdana,sans-serif;color:navy;font-weight:normal;}" + `
	"TABLE{border-width:1px;cellpadding=10;border-style:solid;border-color:navy;border-collapse:collapse;}" + `
	"TH{font-size:12px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}" + `
	"TD{font-size:10px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}</Style>"
	Function SendEmailStatus($From, $To, $Subject, $SMTPServer, $BodyAsHtml, $Body)
	{	$SMTPMessage = New-Object System.Net.Mail.MailMessage $From, $To, $Subject, $Body
		$SMTPMessage.IsBodyHTML = $BodyAsHtml
		$SMTPClient = New-Object System.Net.Mail.SMTPClient $SMTPServer
		$SMTPClient.Send($SMTPMessage)
		If($? -eq $False){Write-Warning "$($Error[0].Exception.Message) | $($Error[0].Exception.GetBaseException().Message)"}
		$SMTPMessage.Dispose()
		rv SMTPClient
		rv SMTPMessage
	}
	$ShadowCopyStats = @()
	Function GetShadowCopyStats
	{	Param($Computer)
		If(!$Computer){Write-Warning "You need to provide a computer to query!"; Return}
		If($Computer.GetType().Name -match "ADComputer")
		{If($Computer.dnsHostName -ne $Null){$Computer = $Computer.dnsHostName}Else{$Computer = $Computer.Name}}
		Write-Progress -Activity "Retrieving snapshot statistics." -Status "Processing server: $Computer" -ID 1
		$bOnline = $bWMIConnection = $False
		If($Computer -ne ".")
		{	$Ping = New-Object system.Net.NetworkInformation.Ping
			If(($Ping.Send($Computer, $TimeOut)).Status -eq 'Success'){}Else{Write-Warning "$Computer is not pingable..."; return}
		}
		$WMITarget = "$Computer"
		Get-WmiObject -Class "Win32_ComputerSystem" -Property "Name" -ComputerName $WMITarget | out-null
		If ($? -eq $False)
		{	$bWMIConnection = $False
			$WMITarget = "$Computer."
			Get-WmiObject -Class "Win32_ComputerSystem" -Property "Name" -ComputerName $WMITarget | out-null
			If($? -eq $False){$bWMIConnection = $False}Else{$bWMIConnection = $True}
		}
		Else{$bWMIConnection = $True}
		If($bWMIConnection)
		{	Write-Progress -Activity "Retrieving computer volumes..." -Status "....." -ID 2 -ParentID 1
			$Volumes = gwmi Win32_Volume -Property SystemName,DriveLetter,DeviceID,Capacity,FreeSpace -Filter "DriveType=3" -ComputerName $WMITarget |
				Select SystemName,@{n="DriveLetter";e={$_.DriveLetter.ToUpper()}},DeviceID,@{n="CapacityGB";e={([math]::Round([int64]($_.Capacity)/1GB,2))}},@{n="FreeSpaceGB";e={([math]::Round([int64]($_.FreeSpace)/1GB,2))}} | Sort DriveLetter
			Write-Progress -Activity "Retrieving shadow storage areas..." -Status "....." -ID 2 -ParentID 1
			$ShadowStorage = gwmi Win32_ShadowStorage -Property AllocatedSpace,DiffVolume,MaxSpace,UsedSpace,Volume -ComputerName $WMITarget |
				Select @{n="Volume";e={$_.Volume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
				@{n="DiffVolume";e={$_.DiffVolume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
				@{n="AllocatedSpaceGB";e={([math]::Round([int64]($_.AllocatedSpace)/1GB,2))}},
				@{n="MaxSpaceGB";e={([math]::Round([int64]($_.MaxSpace)/1GB,2))}},
				@{n="UsedSpaceGB";e={([math]::Round([int64]($_.UsedSpace)/1GB,2))}}
			Write-Progress -Activity "Retrieving shadow copies..." -Status "....." -ID 2 -ParentID 1
			$ShadowCopies = gwmi Win32_ShadowCopy -Property VolumeName,InstallDate,Count -ComputerName $WMITarget |
				Select VolumeName,InstallDate,Count,
				@{n="CreationDate";e={$_.ConvertToDateTime($_.InstallDate)}}
			Write-Progress -Activity "Retrieving shares..." -Status "....." -ID 2 -ParentID 1
			$Shares = gwmi win32_share -Property Name,Path -ComputerName $WMITarget | Select Name,@{n="Path";e={$_.Path.ToUpper()}}
			If($Volumes)
			{
				$Output = @()
				ForEach($Volume in $Volumes)
				{
					$VolumeShares = $VolumeShadowStorage = $DiffVolume = $VolumeShadowCopies = $Null
					If($Volume.DriveLetter -ne $Null){[array]$VolumeShares = $Shares | ?{$_.Path.StartsWith($Volume.DriveLetter)}}
					$VolumeShadowStorage = $ShadowStorage | ?{$_.Volume -eq $Volume.DeviceID}
					If($VolumeShadowStorage){$DiffVolume = $Volumes | ?{$_.DeviceID -eq $VolumeShadowStorage.DiffVolume}}
					$VolumeShadowCopies = $ShadowCopies | ?{$_.VolumeName -eq $Volume.DeviceID} | Sort InstallDate
					$Object = New-Object psobject
					$Object | Add-Member NoteProperty SystemName $Volume.SystemName -PassThru | Add-Member NoteProperty DriveLetter $Volume.DriveLetter -PassThru |
						Add-Member NoteProperty CapacityGB $Volume.CapacityGB -PassThru | Add-Member NoteProperty FreeSpaceGB $Volume.FreeSpaceGB -PassThru |
						Add-Member NoteProperty ShareCount "" -PassThru | Add-Member NoteProperty Shares "" -PassThru |
						Add-Member NoteProperty ShadowAllocatedSpaceGB "" -PassThru | Add-Member NoteProperty ShadowUsedSpaceGB "" -PassThru |
						Add-Member NoteProperty ShadowMaxSpaceGB "" -PassThru | Add-Member NoteProperty DiffVolumeDriveLetter "" -PassThru |
						Add-Member NoteProperty DiffVolumeCapacityGB "" -PassThru | Add-Member NoteProperty DiffVolumeFreeSpaceGB "" -PassThru |
						Add-Member NoteProperty ShadowCopyCount "" -PassThru | Add-Member NoteProperty OldestShadowCopy "" -PassThru |
						Add-Member NoteProperty LatestShadowCopy "" -PassThru | Add-Member NoteProperty ShadowAverageSizeGB "" -PassThru | Add-Member NoteProperty ShadowAverageSizeMB ""
					If($VolumeShares)
					{	$Object.ShareCount = $VolumeShares.Count
						If($VolumeShares.Count -eq 1){$Object.Shares = $VolumeShares[0].Name}
						Else{$Object.Shares = [string]::join(", ", ($VolumeShares | Select Name)).Replace("@{Name=", "").Replace("}", "")}
					}
					If($VolumeShadowStorage)
					{	$Object.ShadowAllocatedSpaceGB = $VolumeShadowStorage.AllocatedSpaceGB
						$Object.ShadowUsedSpaceGB = $VolumeShadowStorage.UsedSpaceGB
						$Object.ShadowMaxSpaceGB = $VolumeShadowStorage.MaxSpaceGB
						If($DiffVolume)
						{	$Object.DiffVolumeDriveLetter = $DiffVolume.DriveLetter
							$Object.DiffVolumeCapacityGB = $DiffVolume.CapacityGB
							$Object.DiffVolumeFreeSpaceGB = $DiffVolume.FreeSpaceGB
						}
					}
					If($VolumeShadowCopies)
					{	$Object.ShadowCopyCount = (($VolumeShadowCopies | Measure-Object -Property Count -Sum).Sum)
						$Object.OldestShadowCopy = (($VolumeShadowCopies | Select -First 1).CreationDate)
						$Object.LatestShadowCopy = (($VolumeShadowCopies | Select -Last 1).CreationDate)
						If($VolumeShadowStorage.UsedSpaceGB -gt 0 -And $Object.ShadowCopyCount -gt 0)
						{	$Object.ShadowAverageSizeGB = ([math]::Round($VolumeShadowStorage.UsedSpaceGB/$Object.ShadowCopyCount,2))
							$Object.ShadowAverageSizeMB = ([math]::Round(($VolumeShadowStorage.UsedSpaceGB*1KB)/$Object.ShadowCopyCount,2))
						}
					}
					If($VolumeShadowStorage -Or $ShowAllVolumes){$Output += $Object}
				}
				$Output
			}
			Else{Write-Warning "$Computer didn't return any volumes. That's just weird..."; return}
		}
		Else{Write-Warning "$Computer is not contactable over WMI..."; return}
	}
}
Process
{	If($ServerName)
	{ForEach($Server in $ServerName){$ShadowCopyStats += GetShadowCopyStats $Server}}
	Else
	{$ShadowCopyStats += GetShadowCopyStats $_}
}
End
{	$ErrorActionPreference = $script:CurrentErrorActionPreference
	If($EmailLog)
	{	SendEmailStatus -From $From -To $To -Subject $Subject -SmtpServer $SmtpServer -BodyAsHtml $True -Body ($ShadowCopyStats | ConvertTo-HTML -head $Style)
	}
	$ShadowCopyStats
}