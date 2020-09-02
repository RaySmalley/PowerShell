# .Net check
if ((Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -lt 379893) {
    Write-Output ".NET Framework 4.5.2 or greater not installed. Exiting..."
    Exit 1
}

# PowerShell version check
function Get-WMF51 {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
    $URL = "https://www.microsoft.com/en-us/download/details.aspx?id=54616"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $URL -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to WMF: $URL with error $_."
        Break
    }
    finally {
        $WMFUri = $response.links | Where-Object {$_.outerHTML -like "*click here to download manually*"}
        Write-Output $WMFUri.href
    }
}

if ([Version]$host.version -lt [Version]5.1.00000.0) {
    Write-Output "PowerShell version is less than 5.1. Attempting to install..."
    
}

if (-Not (Get-Module -ListAvailable -Name CredentialManager)) {Install-Module -Name CredentialManager -Force}
Import-Module -Name CredentialManager -Force
(Get-StoredCredential -AsCredentialObject) | Select TargetName,UserName | Where {$_ -match "administrator"}