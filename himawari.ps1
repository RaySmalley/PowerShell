#
# Himawari-8 Downloader
#
#
#
# This script will scrape the latest image from the Himawari-8 satellite, recombining the tiled image,
# converting it to a JPG which is saved in My Pictures\Himawari\ and then set as the desktop background.
#
# http://himawari8.nict.go.jp/himawari8-image.htm
#
#

 
$ts = New-TimeSpan -Hours -5 -Minutes -0 #Number of hours and minutes to add/subtract to the date. Adjust this to offset your system date to around about GMT (I think?)
$now = ((Get-Date -Second 00) + $ts)
$now = $now.AddMinutes(-($now.minute % 10))



$width = 550
$level = "4d" #Level can be 4d, 8d, 16d, 20d 
$numblocks = 4 #this apparently corresponds directly with the level, keep this exactly the same as level without the 'd'
$time = $now.ToString("HHmmss")
$year = $now.ToString("yyyy")
$month = $now.ToString("MM")
$day = $now.ToString("dd")

#Create the folder My Pictures\Himawari\ if it doesnt exist
$outpath = [Environment]::GetFolderPath("MyPictures") + "\Himawari\"
if(!(Test-Path -Path $outpath ))
{
    [void](New-Item -ItemType directory -Path $outpath)
}

#The filename that will be saved:
#Uncomment this to have the files accumulate in the directory:
#$outfile = "$year$month$day"+"_" + $time + ".jpg" 
#Use this to have the script just store the latest file only:
$outfile = "latest.jpg" 


$url = "http://himawari8-dl.nict.go.jp/himawari8/img/D531106/$level/$width/$year/$month/$day/$time"

[void][reflection.assembly]::LoadWithPartialName("System.Drawing")

$image = New-Object System.Drawing.Bitmap(($width * $numblocks), ($width * $numblocks))
$graphics = [System.Drawing.Graphics]::FromImage($image)
$graphics.Clear([System.Drawing.Color]::Black)

for ($y = 0; $y -lt $numblocks; $y++)
{
for ($x = 0; $x -lt $numblocks; $x++)
{
    $thisurl = $url + "_" + [String]$x + "_" + [String]$y + ".png"
    Write-Output "Downloading: $thisurl"
    
    try
    {
    
        $request = [System.Net.WebRequest]::create($thisurl)
        $response = $request.getResponse()
        $HTTP_Status = [int]$response.StatusCode
        If ($HTTP_Status -eq 200)
        { 
            $imgblock = [System.Drawing.Image]::fromStream($response.getResponseStream())
            $graphics.DrawImage($imgblock,($x*$width),($y*$width) , $width, $width)   
            $imgblock.dispose()
            $response.Close()
        }
    }
    Catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Output "Failed! $ErrorMessage with $FailedItem"
    }
}
}


$qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)

# Set JPEG quality level here: 0 - 100 (inclusive bounds)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($qualityEncoder, 90)
$jpegCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | where {$_.MimeType -eq 'image/jpeg'}

$image.save(($outpath + $outfile), $jpegCodecInfo, $encoderParams)
$image.Dispose()

<#
 Different settings for the wallpaper:
 
                            Tile :
                                key.SetValue(@"WallpaperStyle", "0") ; 
                                key.SetValue(@"TileWallpaper", "1") ; 
                                break;
                            Center :
                                key.SetValue(@"WallpaperStyle", "0") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
                            Stretch :
                                key.SetValue(@"WallpaperStyle", "2") ; 
                                key.SetValue(@"TileWallpaper", "0") ;
                                break;
                            Fill :
                                key.SetValue(@"WallpaperStyle", "10") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
                            Fit :
                                key.SetValue(@"WallpaperStyle", "6") ; 
                                key.SetValue(@"TileWallpaper", "0") ; 
                                break;
#>


Write-Output "Setting Wallpaper..."
Set-ItemProperty -path "HKCU:Control Panel\Desktop" -name Wallpaper -value ($outpath + $outfile)
Set-ItemProperty -path "HKCU:Control Panel\Desktop" -name WallpaperStyle -value 6
Set-ItemProperty -path "HKCU:Control Panel\Desktop" -name TileWallpaper -value 0
Set-ItemProperty 'HKCU:\Control Panel\Colors' -name Background -Value "0 0 0"
#rundll32.exe user32.dll, UpdatePerUserSystemParameters


$setwallpapersource = @"
using System.Runtime.InteropServices;
public class wallpaper
{
public const int SetDesktopWallpaper = 20;
public const int UpdateIniFile = 0x01;
public const int SendWinIniChange = 0x02;
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
public static void SetWallpaper ( string path )
{
SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
}
}
"@
Add-Type -TypeDefinition $setwallpapersource
[wallpaper]::SetWallpaper(($outpath + $outfile))


Write-Output "Done"
