Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"



Function Ensure-Folder()
{
Param(
  [Parameter(Mandatory=$True)]
  [Microsoft.SharePoint.Client.Web]$Web,

  [Parameter(Mandatory=$True)]
  [Microsoft.SharePoint.Client.Folder]$ParentFolder, 

  [Parameter(Mandatory=$True)]
  [String]$FolderUrl

)

    $folderNames = $FolderUrl.Trim().Split("/",[System.StringSplitOptions]::RemoveEmptyEntries)
    $folderName = $folderNames[0]
    Write-Host "Creating folder [$folderName] ..."
    $curFolder = $ParentFolder.Folders.Add($folderName)
    $Web.Context.Load($curFolder)
    $web.Context.ExecuteQuery()
    Write-Host "Folder [$folderName] has been created succesfully. Url: $($curFolder.ServerRelativeUrl)"

    if ($folderNames.Length -gt 1)
    {
        $curFolderUrl = [System.String]::Join("/", $folderNames, 1, $folderNames.Length - 1)
        Ensure-Folder -Web $Web -ParentFolder $curFolder -FolderUrl $curFolderUrl
    }
}



Function Upload-File() 
{
Param(
  [Parameter(Mandatory=$True)]
  [Microsoft.SharePoint.Client.Web]$Web,

  [Parameter(Mandatory=$True)]
  [String]$FolderRelativeUrl, 

  [Parameter(Mandatory=$True)]
  [System.IO.FileInfo]$LocalFile

)

    try {
       $fileUrl = $FolderRelativeUrl + "/" + $LocalFile.Name
       Write-Host "Uploading file [$($LocalFile.FullName)] ..."
       [Microsoft.SharePoint.Client.File]::SaveBinaryDirect($Web.Context, $fileUrl, $LocalFile.OpenRead(), $true)
       Write-Host "File [$($LocalFile.FullName)] has been uploaded succesfully. Url: $fileUrl"
    }
    catch {
       write-host "An error occured while uploading file [$($LocalFile.FullName)]"
    }
}




function Upload-Files()
{

Param(
  [Parameter(Mandatory=$True)]
  [String]$Url,

  [Parameter(Mandatory=$True)]
  [String]$UserName,

  [Parameter(Mandatory=$False)]
  [String]$Password, 

  [Parameter(Mandatory=$True)]
  [String]$TargetListTitle,

  [Parameter(Mandatory=$True)]
  [String]$SourceFolderPath

)

    if($Password) {
        $SecurePassword = $Password | ConvertTo-SecureString
    }
    else {
        $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString
    }
    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName,$SecurePassword)
    $Context.Credentials = $Credentials


    $web = $Context.Web 
    $Context.Load($web)
    $list = $web.Lists.GetByTitle($TargetListTitle);
    $Context.Load($list.RootFolder)
    $Context.ExecuteQuery()

    Get-ChildItem $SourceFolderPath -Recurse | Where { $_.LastWriteTime -gt (Get-Item $LogFile).LastWriteTime } | % {
        if ($_.PSIsContainer -eq $True) {
            $folderUrl = $_.FullName.Replace($SourceFolderPath,"").Replace("\","/")   
            if($folderUrl) {
                Ensure-Folder -Web $web -ParentFolder $list.RootFolder -FolderUrl $folderUrl
            }  
        }
        else{
            $folderRelativeUrl = $list.RootFolder.ServerRelativeUrl + $_.DirectoryName.Replace($SourceFolderPath,"").Replace("\","/")  
            Upload-File -Web $web -FolderRelativeUrl $folderRelativeUrl -LocalFile $_
        }
    }
}



# Usage


$Url = "https://415group.sharepoint.com"
$UserName = "rsmalley@415group.net"
$Password = Get-Content "C:\Users\RES\Documents\SP-PW.txt" # Read-Host "Enter Password" -AsSecureString | ConvertFrom-SecureString | Out-File "C:\Users\RES\Documents\SP-PW.txt"
$TargetListTitle = "Documents"   #Target Library
$SourceFolderPath = "\\FILESERVER1\data\ITC\Documentation"  # Source Physical Path 
$LogFile = "C:\Users\RES\Documents\SP-UploadLog.txt"

# Create log file if it doesn't exist
If (!(Test-Path $LogFile)) { Out-File $LogFile } 

# Upload files
Upload-Files -Url $Url -UserName $UserName -Password $Password -TargetListTitle $TargetListTitle -SourceFolderPath $SourceFolderPath

Out-File $LogFile

#$error[0]|format-list -force