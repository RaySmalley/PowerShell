#PowerShell Script 
#This script deletes all shadow copies older than 1 days

Get-WmiObject Win32_Shadowcopy | ForEach-Object {

    $WmiSnapShotDate = $_.InstallDate
    $strShadowID = $_.ID
    $dtmSnapShotDate = [management.managementDateTimeConverter]::ToDateTime($WmiSnapShotDate) 
    $strClientAccessible = $_.ClientAccessible
    $dtmCurDate = Get-Date
    $dtmTimeSpan = New-TimeSpan $dtmSnapShotDate $dtmCurDate 
    $intNumberDays = $dtmTimeSpan.Days

    If ($intNumberDays -ge 1 -and $strClientAccessible -eq "True") {
        $_.Delete()
    }
}

