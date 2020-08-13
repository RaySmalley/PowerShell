# Windows Updates
Write-Host "Checking for Windows Updates..."`n
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { 
    Install-PackageProvider -Name NuGet -Force
    Install-Module PSWindowsUpdate -Force
}
if (Get-WindowsUpdate -AcceptAll -Install -AutoReboot) {
    Write-Host "Windows Updates installed."`n
} else {
    Write-Host "No updates available."`n
}