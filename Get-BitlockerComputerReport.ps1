# 
# 
# NAME: Get-BitlockerComputerReport.ps1 
# 
# AUTHOR: Jan Egil Ring 
# EMAIL: jan.egil.ring@crayon.com 
# 
# COMMENT: Script to retrieve BitLocker-information for all computer objects with Windows 7 or Windows Vista in the current domain. 
# 
#          The information will be exported to a CSV-file containing the following information: 
#          -Computername 
#          -OperatingSystem 
#          -HasBitlockerRecoveryKey 
#          -HasTPM-OwnerInformation 
#           
#          Required version: Windows PowerShell 1.0 or 2.0 
#          Required snapins: Quest.ActiveRoles.ADManagement 
#          Requried privileges: Read-permission on msFVE-RecoveryInformation objects and Read-permissions on msTPM-OwnerInformation on computer-objects (e.g. Domain Admins) 
#           
#          For more information, see the following blog-post: http://blog.powershell.no/2010/10/24/export-bitlocker-information-using-windows-powershell 
#       
# You have a royalty-free right to use, modify, reproduce, and 
# distribute this script file in any way you find useful, provided that 
# you agree that the creator, owner above has no warranty, obligations, 
# or liability for such use. 
# 
# VERSION HISTORY: 
# 1.0 24.10.2010 - Initial release 
#  
# 
 
Add-PSSnapin Quest.ActiveRoles.ADManagement -ErrorAction Stop

#Custom variables 
$CsvFilePath = "C:\temp\BitLockerComputerReport.csv" 
 
#Export computers not Bitlocker-enabled to a CSV-file 
$BitLockerEnabled = Get-QADObject -SizeLimit 0 -IncludedProperties Name,ParentContainer | Where-Object {$_.type -eq "msFVE-RecoveryInformation"} | Foreach-Object {Split-Path -Path $_.ParentContainer -Leaf} | Select-Object -Unique 
$computers = Get-QADComputer -SizeLimit 0 -IncludedProperties Name,OperatingSystem,msTPM-OwnerInformation | Where-Object {$_.operatingsystem -like "Windows 7*" -or $_.operatingsystem -like "Windows Vista*"} | Sort-Object Name 
 
#Create array to hold computer information 
$export = @() 
 
 
foreach ($computer in $computers) 
  { 
    #Create custom object for each computer 
    $computerobj = New-Object -TypeName psobject 
     
    #Add name and operatingsystem to custom object 
    $computerobj | Add-Member -MemberType NoteProperty -Name Name -Value $computer.Name 
    $computerobj | Add-Member -MemberType NoteProperty -Name OperatingSystem -Value $computer.operatingsystem 
     
    #Set HasBitlockerRecoveryKey to true or false, based on matching against the computer-collection with BitLocker recovery information 
    if ($computer.name -match ('(' + [string]::Join(')|(', $bitlockerenabled) + ')')) { 
    $computerobj | Add-Member -MemberType NoteProperty -Name HasBitlockerRecoveryKey -Value $true 
    } 
    else 
    { 
    $computerobj | Add-Member -MemberType NoteProperty -Name HasBitlockerRecoveryKey -Value $false 
    } 
     
    #Set HasTPM-OwnerInformation to true or false, based on the msTPM-OwnerInformation on the computer object 
     if ($computer."msTPM-OwnerInformation") { 
    $computerobj | Add-Member -MemberType NoteProperty -Name HasTPM-OwnerInformation -Value $true 
    } 
    else 
    { 
    $computerobj | Add-Member -MemberType NoteProperty -Name HasTPM-OwnerInformation -Value $false 
    } 
     
#Add the computer object to the array with computer information 
$export += $computerobj 
 
  } 
 
#Export the array with computerinformation to the user-specified path 
$export | Export-Csv -Path $CsvFilePath -NoTypeInformation