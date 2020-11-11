if (Get-Process WRSA -ErrorAction SilentlyContinue) {
    if (Test-Path "C:\Program Files\Webroot\WRSA.exe") { & "C:\Program Files\Webroot\WRSA.exe" -uninstall }
    if (Test-Path "C:\Program Files (x86)\Webroot\WRSA.exe") { & "C:\Program Files (x86)\Webroot\WRSA.exe" -uninstall }
    Start-Sleep 15
    if (Get-Process WRSA -ErrorAction SilentlyContinue) {
        Write-Output "Webroot removal failed."
        Exit 2
    } else {
        Write-Output "Webroot removal successful."
    }
} else {
    Write-Output "Webroot is not running. Exiting..."
    Exit 1
}