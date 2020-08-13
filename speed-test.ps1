### Could add whether connection is WiFi or Ethernet

$serverInformation = @()
$speedResults = @()
$serverCount = 5

Function downloadSpeed($strUploadUrl)
{
	$topServerUrlSplit = $strUploadUrl -split 'upload'
	$url = $topServerUrlSplit[0] + 'random1000x1000.jpg'
    $domain = ([System.Uri]"$url").Authority
    
    if (Test-Connection -Count 1 -Quiet $domain) { 
        $downloadData = (New-Object System.Net.WebClient).DownloadData($url)
        $downloadSize = [System.Text.Encoding]::ASCII.GetString($downloadData).Length / 1Mb
        $downloadTime = (Measure-Command { $downloadData }).TotalSeconds
        $downloadSpeed = ($downloadSize / $downloadTime) * 8
	} else { 
        $downloadSpeed = 0
        $global:serverCount += 1
    }
    return $downloadSpeed
}

<#
Using this method to make the submission to speedtest. Its the only way i could figure out how to interact with the page since there is no API.
More information for later here: https://support.microsoft.com/en-us/kb/290591
#>
$objXmlHttp = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp.Open("GET", "http://www.speedtest.net/speedtest-config.php", $False)
$objXmlHttp.Send()

# Retrieving the content of the response.
[xml]$content = $objXmlHttp.responseText

<#
Gives me the Latitude and Longitude so i can pick the closer server to me to actually test against. It doesnt seem to automatically do this.
Lat and Longitude for tampa at my house are $orilat = 27.9238 and $orilon = -82.3505
This is corroborated against: http://www.travelmath.com/cities/Tampa,+FL - It checks out.
#>
$oriLat = $content.settings.client.lat
$oriLon = $content.settings.client.lon

# Making another request. This time to get the server list from the site.
$objXmlHttp1 = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp1.Open("GET", "http://www.speedtest.net/speedtest-servers.php", $False)
$objXmlHttp1.Send()

# Retrieving the content of the response.
[xml]$serverList = $objXmlHttp1.responseText

<#
$cons contains all of the information about every server in the speedtest.net database. 
I was going to filter this to US servers only which would speed this up a lot but i know we have overseas partners we run this against. 
Results returned look like this for each individual server:

url     : http://speedtestnet.rapidsys.com/speedtest/upload.php
lat     : 27.9709
lon     : -82.4646
name    : Tampa, FL
country : United States
cc      : US
sponsor : Rapid Systems
id      : 1296

#>
$cons = $serverList.settings.servers.server 
 
# Below we calculate servers relative closeness to you by doing some math against latitude and longitude. 
ForEach($val in $cons) 
{ 
	$R = 6371;
	[float]$dlat = ([float]$oriLat - [float]$val.lat) * 3.14 / 180;
	[float]$dlon = ([float]$oriLon - [float]$val.lon) * 3.14 / 180;
	[float]$a = [math]::Sin([float]$dLat/2) * [math]::Sin([float]$dLat/2) + [math]::Cos([float]$oriLat * 3.14 / 180 ) * [math]::Cos([float]$val.lat * 3.14 / 180 ) * [math]::Sin([float]$dLon/2) * [math]::Sin([float]$dLon/2);
	[float]$c = 2 * [math]::Atan2([math]::Sqrt([float]$a ), [math]::Sqrt(1 - [float]$a));
	[float]$d = [float]$R * [float]$c;
	
	$serverInformation +=
@([pscustomobject]@{Distance = $d; Country = $val.country; Sponsor = $val.sponsor; Url = $val.url })

}

# Sort servers by ascending distance
$serverInformation = $serverInformation | Sort-Object -Property Distance

# Loop through the 4 closest servers and take highest speed result.
$i = 0
While ($i -lt $serverCount) {
    $speedResults += downloadSpeed($serverInformation[$i].Url)
    $i++    
}

$wanSpeed = [Math]::Round(($speedResults | Measure -Maximum).Maximum)

# Output result
Write-Host WAN Speed: $wanSpeed Mbit/Sec