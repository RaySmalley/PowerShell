Add-PSSnapin -Name VeeamPSSnapin
Connect-VBRServer -Server localhost

#$OldRepoDailies = Get-VBRBackupRepository -Name "CTMNAS01-2"
#$OldRepoMonthlies = Get-VBRBackupRepository -Name "CTMNAS01-LongTerm"
#$NewRepoDailies = Get-VBRBackupRepository -Name "CTMNAS02-Dailies"
#$NewRepoMonthlies = Get-VBRBackupRepository -Name "CTMNAS02-Monthlies"

$Jobs = Get-VBRJob | Where {$_.JobType -eq "Backup"} 

Foreach ($Job in $Jobs) {
    $JobName = $Job.Name
    $JobRepo = ($Job).GetTargetRepository().Name
    $JobFolder = $Job.TargetFile
    if ($JobRepo -match "CTMNAS01") {
        Write-Host "$JobName - $JobRepo - $JobFolder"

    }
}

Disconnect-VBRServer