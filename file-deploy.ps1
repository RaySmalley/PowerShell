[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = "C:\"
$OpenFileDialog.filter = "All files (*.*)| *.*"
$OpenFileDialog.ShowDialog() | Out-Null
$file = $OpenFileDialog.filename

$computerList = "$env:temp\computers.txt"

New-Item $computerList -ErrorAction Ignore

notepad.exe $computerList | Out-Null

$computers = Get-Content -Path $computerList

foreach ($computer in $computers) {
    Write-Host "Copying $file to $computer..."`n
    Copy-Item $file "\\$computer\C$\Temp\"
}