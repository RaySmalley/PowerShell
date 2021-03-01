Get-ADUser -filter {profilePath -Like "*" -and enabled -eq "true"} -Properties profilePath | Select Name | Sort Name

Read-Host Press enter to continue