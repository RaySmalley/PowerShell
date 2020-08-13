# This sample script recreates the SBSMonitoring Database in SBS 2008 or SBS 2011 Standard.
# Creates a new SBSMonitoring Database (renames an existing one if present).
# Creates the 2 default Reports
# Computer population will take place within 30 minutes as per the DataCollectorSvc schedule
# In SBS 2011 std it requires Framework v4 Assemblies - Launch MoveDataPowerShellHost.exe as an admin from SBS BIN folder, then run this PS1
#
# Check http://blogs.technet.com/b/sbs for more information
#
# This sample script is provided AS IS without warranty of any kind.
# Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
# In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages. 

#Create SQL scripts
get-content "C:\Program Files\Windows Small Business Server\data\Monitoring\DatabaseSetup.sql" | 
ForEach-Object {$_ -replace "\{0}","SBSMonitoring"} | 
set-content c:\windows\temp\DatabaseSetup-new.sql

get-content "C:\Program Files\Windows Small Business Server\data\Monitoring\Tables.sql" | 
ForEach-Object {$_ -replace "\{0}","SBSMonitoring"} | 
set-content c:\windows\temp\Tables-new.sql

get-content "C:\Program Files\Windows Small Business Server\data\Monitoring\StoredProcedures.sql" | 
ForEach-Object {$_ -replace "\{0}","SBSMonitoring"} | 
set-content c:\windows\temp\StoredProcedures-new.sql

Stop-Service DataCollectorSvc -Force
Stop-Service 'MSSQL$SBSMONITORING' -Force

$date=Get-Date -format 'yyyy_MM_dd_hh_mm_ss'

#Find path for SBSMonitoring installation
if ((gwmi win32_operatingsystem).version -like "6.0*") {
	#SBS2008 : HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\SBSMONITORING\Setup\SQLPath
	$key=get-itemproperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\SBSMONITORING\Setup\"
} else
{
	#SBS2011 : HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\SBSMONITORING\Setup\SQLPath
	$key=get-itemproperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SBSMONITORING\Setup\"
}

$dbpath=$key.SQLpath+"\Data\SBSMonitoring.mdf"
$ldpath=$key.SQLpath+"\Data\SBSMonitoring_log.LDF"
if (test-path $dbpath) {
	ren $dbpath -NewName "SBSMonitoring.mdf.$date"
	Write-Host Backup file created - remove it after functionality is restored to recover the disk space "$dpath.$date" 
	}
if (test-path $ldpath) {
	ren $ldpath -NewName "SBSMonitoring_log.LDF.$date" 
	Write-Host Backup file created - remove it after functionality is restored to recover the disk space "$ldpath.$date"
	}


Start-Service 'MSSQL$SBSMONITORING'


sqlcmd -E -S $env:COMPUTERNAME\SBSMonitoring -i c:\windows\temp\DatabaseSetup-new.sql | Out-Null
sqlcmd -E -S $env:COMPUTERNAME\SBSMonitoring -i c:\windows\temp\Tables-new.sql | Out-Null
sqlcmd -E -S $env:COMPUTERNAME\SBSMonitoring -i c:\windows\temp\StoredProcedures-new.sql | Out-Null

Start-Service DataCollectorSvc


[system.reflection.assembly]::LoadFrom("c:\program files\Windows small business server\bin\MonitoringCommon.dll")

## Summary Report
$reportContent = new-object Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContent($null)
$reportContent.Add([Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContentType]::Summary)
$sch1 = new-object Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.Scheduler(3,15)

$summaryReport = new-object Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportConfiguration([Guid]"86949FAC-C719-42AE-A8C2-0C43CBE64927","Summary Network Report","This report includes summary information about the performance of your network.",$true,$reportContent,"",$sch1)

$MailEnabledDistributionListQuery = "(&(objectCategory=group)(groupType:1.2.840.113556.1.4.803:=8)(!groupType:1.2.840.113556.1.4.803:=2147483648)(mail=*)(sAMAccountName=Windows SBS Administrators))"
$reportDomainRecipients = New-Object Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.UserCollection($null)
$reportDomainRecipients = [Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ADUtil]::GetUsers($MailEnabledDistributionListQuery)

$summaryReport.DomainEmailAddresses = $reportDomainRecipients

$out = "INSERT INTO ReportConfiguration (ID, Name, Description, Enabled, Content, DomainUserEmails, ExternalUserEmails, Schedule) VALUES(`'"+$summaryReport.Id+"`',`'"+$summaryReport.Name+"`',`'"+$summaryReport.Description+"`',`'"+$true+"`',`'"+$summaryReport.Content+"`',`'"+$summaryReport.DomainEmailAddressesXML+"`',`'"+$summaryReport.ExternalEmailAddresses+"`',`'"+$summaryReport.ScheduleXML+"`')"
"use SBSMonitoring" | Out-File -FilePath c:\windows\Temp\TempQuery.sql 
$out | Out-File -FilePath c:\windows\Temp\TempQuery.sql -Append


## Full Report
$reportContent.Add([Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContentType]::Security)
$reportContent.Add([Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContentType]::Updates)
$reportContent.Add([Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContentType]::Backup)
$reportContent.Add([Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContentType]::OtherAlerts)
$reportContent.Add([Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContentType]::EmailUsage)
$reportContent.Add([Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportContentType]::EventLog)

$sch2 = new-object Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.Scheduler(3,15,"Sunday")
$fullReport = new-object Microsoft.WindowsServerSolutions.SystemHealth.Monitoring.ReportConfiguration([Guid]"13B8397F-B197-4E5B-B3D0-340FCB5E216A","Detailed Network Report","This report includes detailed information about the performance of your network.",$true,$reportContent,"",$sch2)
$fullReport.DomainEmailAddresses = $reportDomainRecipients

$out = "INSERT INTO ReportConfiguration (ID, Name, Description, Enabled, Content, DomainUserEmails, ExternalUserEmails, Schedule) VALUES(`'"+$fullReport.Id+"`',`'"+$fullReport.Name+"`',`'"+$fullReport.Description+"`',`'"+$true+"`',`'"+$fullReport.Content+"`',`'"+$fullReport.DomainEmailAddressesXML+"`',`'"+$fullReport.ExternalEmailAddresses+"`',`'"+$fullReport.ScheduleXML+"`')"
$out | Out-File -FilePath c:\windows\Temp\TempQuery.sql -Append

##Create
sqlcmd -E -S $env:COMPUTERNAME\SBSMonitoring -i c:\windows\temp\TempQuery.sql


