# Only run if Windows 10 or higher
If ((Get-WmiObject win32_operatingsystem).version -lt 10) {exit}

# Set paths
$sourceDir = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
$destDir = "$env:USERPROFILE\Pictures\Wallpaper"

# Create destination directory
md -Force $destDir > $null

# Copy and rename images if they are 1920x1080 and larger than 100kb
cd $sourceDir
$(Get-ChildItem) | ForEach-Object {
    $img = [Drawing.Image]::FromFile($_.FullName)
    $dimensions = "$($img.Width) x $($img.Height)"
    $size = $_.Length

    If ($dimensions -eq "1920 x 1080" -and $size -gt 100kb) {
        Copy-Item -Path $sourceDir\$_ -Destination $destDir\$_.jpg > $null
    }
}

# Set Windows theme
#REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers /v SlideshowDirectoryPath1 /t REG_SZ /d ZEAFA8BUg/E0gouOpBhoYjAArADMdSBAuAI160KJpVKMFhZ4rKQ+BpHqvDQMAAAAAAwqIJanQAwVBxETQFkfyAAAEBQCAQAAv77qIJanrikod6CAAAQqREAAAAg/AAAAAAAAAAAAAAAAAAAAodNZAcFAhBAbAwGAwBQYAAHAlBgcAAAAYAwkAAAAmAw7+WIAAAQMTB1U32pr/3IH/PUgMSIQ6M6ctkGAAAAZAAAAA8BAAAALAAAA3BQaA4GAkBwbAcHAzBgLAkGAtBQbAUGAyBwcAkGA2BQZAMGAvBgbAQHAyBwbAwGAwBQYA4GAlBAbA8FAjBwdAUDAuBQMAgGAyAAdAgHA5BQZAcHA5BAAAAAAAAAAAAAAYAAAAA /f
#REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers /v BackgroundType /t REG_DWORD /d 2 /f
#REG ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers /v SlideshowSourceDirectoriesSet /t REG_DWORD /d 1 /f
#REG ADD "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d $env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper /f
#REG ADD "HKCU\Control Panel\Desktop" /v LastUpdated /t REG_DWORD /d 1 /f