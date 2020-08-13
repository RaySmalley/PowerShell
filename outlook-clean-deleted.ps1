#Shutdown Outlook
#if  ( [bool](Get-Process OUTLOOK* -EA SilentlyContinue) ) {ps OUTLOOK* | kill -Force   ; Start-Sleep -Seconds 10  } 

$Date = [DateTime]::Now.AddDays(-1)

$DeletedItems = ((((New-Object -ComObject Outlook.Application).GetNameSpace("MAPI")).Folders  | ? { $_.Name -eq 'rsmalley@415group.com' }).Folders | ? { $_.Name -match 'Deleted Items' }).Items | Select-Object -Last 1

ForEach ($Item in $DeletedItems) {
    $Item.CreationTime
    $Item.SenderName
    $Item.ConversationTopic
    $Item.Delete()
    Write-Host
}

#Shutdown Outlook
if  ( [bool](Get-Process OUTLOOK* -EA SilentlyContinue) ) {ps OUTLOOK* | kill -Force   ; Start-Sleep -Seconds 5  }