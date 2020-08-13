Write-Host "First, send a test email to create a new Stream_Autocomplete file for the new Outlook profile."
Write-Host "Make sure it created the new file. Sometimes you have to open and close Outlook a couple times."
Read-Host "When sure, close Outlook, then press any key to continue..."`n


While (Get-Process -Name OUTLOOK -ErrorAction SilentlyContinue) {
    Write-Host "Outlook is still open. Please close it to proceed."
        Read-Host "Press Enter when Outlook is closed."`n
}

$RoamCache = "$env:LOCALAPPDATA\Microsoft\Outlook\RoamCache"
$Backup = "C:\Temp"

If (-Not (Test-Path $Backup\RoamCache)) {Copy-Item $RoamCache $Backup -Recurse}

$FullAC = Get-ChildItem -Path $RoamCache | Where-Object { $_.Name -match 'Stream_Autocomplete' } | Sort Length -Descending | Select -First 1

$NewAC = Get-ChildItem -Path $RoamCache | Where-Object { $_.Name -match 'Stream_Autocomplete' } | Sort-Object LastWriteTime -Descending | Select -First 1

If ($NewAC.Length -gt 1KB) {
    $NewAC
    Write-Host "The newest Stream_Autocomplete file is greater than 1KB in size. This probably isn't right."
    $Confirmation = Read-Host "Are you sure you want to proceed?: "
    If ($Confirmation -ne 'y') {
        Write-Host "Exiting..."
        Exit 101
    }
}

If ($NewAC.LastWriteTime -le (Get-Date).addDays(-7)) {
    $NewAC
    Write-Host "Could not find an Stream_Autocomplete file created within the last week."
        $Confirmation = Read-Host "Are you sure you want to proceed?: "
    If ($Confirmation -ne 'y') {
        Write-Host "Exiting..."
        Exit 102
    }
}

Remove-Item $RoamCache\$NewAC

Copy-Item $RoamCache\$FullAC $RoamCache\$FullAC.bak

Rename-Item $RoamCache\$FullAC -NewName $NewAC

Rename-Item $RoamCache\$FullAC.bak -NewName $FullAC