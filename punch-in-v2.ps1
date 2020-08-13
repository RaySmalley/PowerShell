$log = "$env:userprofile\Documents\punch-in.log"

# Date and time variables
$nowDateTime = Get-Date -UFormat "%a %D - %R"
$nowDate = Get-Date -UFormat "%a %D"
$nowTime = Get-Date -UFormat "%R"
$startTime = Get-Date -Hour 7 -Minute 45 -UFormat "%R"
$endTime = Get-Date -Hour 8 -Minute 15 -UFormat "%R"


# Get last punch-in log entry and convert it to DateTime
function getLastEntry {
    $lastLine = (Get-Content $log)[-1]
    $lastEntry = if ($lastLine) { [DateTime]::ParseExact("$(($lastLine).SubString(0,12))", "ddd MM/dd/yy", [System.Globalization.CultureInfo]::InvariantCulture) }
}

getLastEntry

if ($lastEntry -eq (Get-Date).Date) { Exit }

if ($lastLine) {
    # Handling of last entry
    if ((Get-Date $lastEntry -UFormat "%a") -eq "Fri") {
        Add-Content -Value "" -Path $log
        getLastEntry

    }
    elseif ((Get-Date $lastEntry -UFormat "%a") -eq "Tue") {
        Add-Content -Value "$nowDate - Ironrock" -Path $log
        getLastEntry
    }
    else {
        if ($lastEntry -ne (Get-Date).AddDays(-1).Date) {
            Add-Content -Value "$nowDate - No Entry" -Path $log
            getLastEntry
        }
    }

    # Holiday variables
    $year = ($lastEntry).Year
    $month = ($lastEntry).Month
    $day = ($lastEntry).Day
    $date = Get-Date $lastEntry -UFormat "%a %D"
    $holiday = (Invoke-RestMethod "https://holidayapi.com/v1/holidays?key=c824eac0-c2a7-4837-96a1-fecfd2a5041e&country=US&year=$year&month=$month&day=$day&public=true").holidays.name
    
    # Change last entry to Holiday if it was
    if ($holiday) { (Get-Content $log) | ForEach-Object {$_ -Replace "$lastLine", "$date - $holiday"} | Set-Content $log }
}
    

# Create entry if between specified times
if ($nowTime -ge $startTime -and $nowTime -le $endTime) {
    Add-Content -Value $nowDateTime -Path $log
    getLastEntry
} else {
    if (-Not ($lastLine)) {
        Add-Content -Value "$nowDate - No Entry" -Path $log
        getLastEntry
    }
}

# If last entry is more than one day back, add vacation entries to back-fill
#if (-Not ($lastLine)) {
#    $lastLine = (Get-Content $log)[-2]
#    $lastEntry = if ($lastLine) { [DateTime]::ParseExact("$(($lastLine).SubString(0,12))", "ddd MM/dd/yy", [System.Globalization.CultureInfo]::InvariantCulture) }
#}

if (-Not ($lastLine)) {
    $lastLine = (Get-Content $log)[-2]
    $lastEntry = if ($lastLine) { [DateTime]::ParseExact("$(($lastLine).SubString(0,12))", "ddd MM/dd/yy", [System.Globalization.CultureInfo]::InvariantCulture) }
}

$missedDays = (New-TimeSpan -Start $lastEntry -End (Get-Date)).Days
if ($missedDays -gt 1 -and (Get-Date $lastEntry -UFormat "%a") -ne "Fri") {
    $missedDay = 1
    while ($missedDay -lt $missedDays) {
        $vacationDate = Get-Date (Get-Date $nowDate).AddDays(-${missedDay}) -UFormat "%a %D"
        if ((Get-Date $vacationDate -UFormat "%a") -ne "Sat" -And (Get-Date $vacationDate -UFormat "%a") -ne "Sun") {
            #Add-Content -Value "$nowDate - Vacation" -Path $log
            Write-Host "$vacationDate - Vacation"
            getLastEntry
        }
        $missedDay += 1
    }
}