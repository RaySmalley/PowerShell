# Main variables
$log = "$env:userprofile\Documents\punch-in.log"
#$log = "$env:userprofile\Documents\punch-in-test.log"
$nowDateTime = Get-Date -UFormat "%a %D - %R"
$nowDate = Get-Date -UFormat "%a %D"
$nowTime = Get-Date -UFormat "%R"
$startTime = Get-Date -Hour 7 -Minute 45 -UFormat "%R"
$endTime = Get-Date -Hour 8 -Minute 15 -UFormat "%R"

# Get last punch-in log entry and convert it to DateTime
$lastLine = (Get-Content $log)[-1]
$lastEntry = if ($lastLine) { [DateTime]::ParseExact("$(($lastLine).SubString(0,12))", "ddd MM/dd/yy", [System.Globalization.CultureInfo]::InvariantCulture) }

# Create entry if between specified times
if ($nowTime -ge $startTime -and $nowTime -le $endTime) {
    Add-Content -Value $nowDateTime -Path $log
} else {
    if ($lastEntry) { # Everything under here runs M-F @ 6:00 AM and 10:00 AM
        # If last entry was Friday, add blank separator line
        if ((Get-Date $lastEntry -UFormat "%a") -eq "Fri") {
            Add-Content -Value "" -Path $log
        }
        # If last entry was not today's enter Ironrock if it's Wednesday, or No Entry otherwise
        if ($lastEntry -ne (Get-Date).Date) {
            # Holidays
            $year = ($lastEntry).Year
            $month = ($lastEntry).Month
            $day = ($lastEntry).Day
            $date = Get-Date $lastEntry -UFormat "%a %D"
            $holiday = (Invoke-RestMethod "https://holidayapi.com/v1/holidays?key=c824eac0-c2a7-4837-96a1-fecfd2a5041e&country=US&year=$year&month=$month&day=$day&public=true").holidays.name
            # Change last entry to Holiday if it was
            if ($holiday) {
                (Get-Content $log) | ForEach-Object { $_ -Replace "$lastLine", "$date - $holiday" } | Set-Content $log
            }
            # Special days and no entries
            if ((Get-Date -UFormat "%a") -eq "Wed") {
                Add-Content -Value "$nowDate - Ironrock" -Path $log
            } else {
                Add-Content -Value "$nowDate - No Entry" -Path $log
            }
        }
    }
}