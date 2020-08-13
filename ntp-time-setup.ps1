Import-Module ActiveDirectory

if ((Get-ADDomain).PDCEmulator -eq "$env:computername.$env:userdnsdomain") {
    Write-Host "Attempting to sync PDC with time.nist.gov..."
    w32tm.exe /config /manualpeerlist:time.nist.gov /syncfromflags:manual /reliable:yes /update
} else {
    Write-Host "Attempting to sync DC with time.nist.gov..."
    w32tm /config /syncfromflags:domhier /update
}