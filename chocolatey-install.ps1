function chocolatey {
# check if already installed
if (Test-Path C:\ProgramData\chocoportable) { Write-Host "Choco already installed."; Return }

# download and save installation script, then check signature
$url = 'https://chocolatey.org/install.ps1'
$outPath = "$env:temp\installChocolatey.ps1"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $outPath

# test signature
$result = Get-AuthenticodeSignature -FilePath $outPath
if ($result.Status -ne 'Valid')
{
    Write-Warning "Installation Script Damaged/Malware?"
    exit 1
}

# install chocolatey for current user
$env:ChocolateyInstall='C:\ProgramData\chocoportable'

Start-Process -FilePath powershell -ArgumentList "-noprofile -ExecutionPolicy Bypass -File ""$outPath""" -Wait -WindowStyle Hidden

# clean up
Remove-Item -Path $outPath

# assign path
$env:path += ";C:\ProgramData\chocoportable"
}

chocolatey