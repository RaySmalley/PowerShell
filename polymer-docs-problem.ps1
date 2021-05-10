$UserDir = Get-ChildItem 'D:\DFSRoots\sy$\Users' | ?{$_.PSISContainer}
foreach ($User in $UserDir) {
    $DocumentsPath = Join-Path 'D:\DFSRoots\sy$\Users' -ChildPath "$User\Documents"
    $MyDocumentsPath = Join-Path 'D:\DFSRoots\sy$\Users' -ChildPath "$User\My Documents"
    if (Test-Path $DocumentsPath) {
        $DocDate = (Get-Item $DocumentsPath).LastWriteTime
        $DocSize = "{0} MB" -f [math]::round((Get-ChildItem $DocumentsPath -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB)
    } else {
        $DocDate = $null
        $DocSize = $null
    }
    if (Test-Path $MyDocumentsPath) {
        $MyDocDate = (Get-Item $MyDocumentsPath).LastWriteTime
        $MyDocSize = "{0} MB" -f [math]::round((Get-ChildItem $DocumentsPath -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB)
    } else {
        $MyDocDate = $null
        $MyDocSize = $null
    }
    if ((-Not(Test-Path $DocumentsPath)) -and (-Not(Test-Path $MyDocumentsPath))) {Continue}
    if (Get-Content C:\Temp\disabled-users2.txt | Select-String $User) {
        Write-Host "$User (Disabled)" -ForegroundColor Cyan
    } else {
        Write-Host $User
    }
    if ($DocDate -gt $MyDocDate) {
        if ($DocDate -ne $null) {Write-Host "Documents folder modified:    $DocDate   Size: $DocSize" -ForegroundColor Green}
        if ($MyDocDate -ne $null) {Write-Host "My Documents folder modified: $MyDocDate   Size: $MyDocSize"}
        if (Test-Path $MyDocumentsPath) {
            Remove-Item $MyDocumentsPath -Recurse -Force -Confirm
            if (-Not(Test-Path $MyDocumentsPath)) {Write-Host "My Documents folder removed" -ForegroundColor Magenta}
        }
    }
    if ($DocDate -lt $MyDocDate) {
        if ($DocDate -ne $null) {Write-Host "Documents folder modified:    $DocDate   Size: $DocSize"}
        if ($MyDocDate -ne $null) {Write-Host "My Documents folder modified: $MyDocDate   Size: $MyDocSize" -ForegroundColor Red}
    }
    if ($DocDate -eq $MyDocDate) {
        if ($DocDate -ne $null) {Write-Host "Documents folder modified:    $DocDate   Size: $DocSize" -ForegroundColor Yellow}
        if ($MyDocDate -ne $null) {Write-Host "My Documents folder modified: $MyDocDate   Size: $MyDocSize" -ForegroundColor Yellow}
    }
    Write-Host
}