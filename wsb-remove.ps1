# Test for OS version
$os = Get-WmiObject win32_operatingsystem
$osVersion = [single]$os.version.subString(0,3)

if (Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "Backup Manager" }) {
	if ($osVersion -lt 6.2) {
		Remove-WindowsFeature Backup-Features
	} else {
		Uninstall-WindowsFeature Windows-Server-Backup
	}
}