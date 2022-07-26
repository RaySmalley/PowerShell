# Download the latest version of script
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest https://raw.githubusercontent.com/RaySmalley/VHDSizeAnalysis/main/vhd-size-analysis.ps1 -OutFile $PSCommandPath

# Test for elevation
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host '### VHD Size Analysis Script ###'
Write-Host '### Ray Smalley              ###'
Write-Host '### 2020                     ###'`n

$VHDs = Get-VM -VMName * | Select-Object VMid | Get-VHD

$VHDs | Sort Path | ft Path,VhdType,@{label=’Size Now (GB)’;expression={$_.filesize/1GB –as [int]}},@{label=’Max Size (GB)’;expression={$_.size/1GB –as [int]}}

$ResultsTable = @()

ForEach ($Volume in ($VHDs.Path).SubString(0,1) | Sort | Get-Unique) {
    $VolumeInfo = Get-Volume $Volume
    $SumVHDSize = [math]::Round(($VHDs | Where-Object Path -Like "$Volume*" | Measure-Object -Sum Size).Sum / 1GB)
    $MaxDiskSize = [math]::Round(($VolumeInfo).Size / 1GB)
    $OtherDiskSize = $MaxDiskSize - [math]::Round(($VHDs | Where-Object Path -Like "$Volume*" | Measure-Object -Sum FileSize).Sum / 1GB) - [math]::Round(($VolumeInfo).SizeRemaining / 1GB)
    $AvailableSpace = $MaxDiskSize - $SumVHDSize - $OtherDiskSize
    $Results = New-Object -TypeName PSObject -Property @{
        "Volume" = $Volume
        "Used" = $MaxDiskSize - [math]::Round(($VolumeInfo).SizeRemaining / 1GB)
        "Capacity" = "$MaxDiskSize GB"
        "Allocated By VHDs" = "$SumVHDSize GB"
        "Used By Other" = "$OtherDiskSize GB"
        "Available" = "$AvailableSpace GB"
    }
    $ResultsTable += $Results | Select Volume,Used,Capacity,"Allocated By VHDs","Used By Other",Available
}

$ResultsTable | Format-Table -AutoSize

if ($AvailableSpace -lt 0) { Write-Host -ForegroundColor Red "Warning: VHDs are over-provisioned and will cause VM to crash if filled up past host disk capacity. Either free up host disk space used by files other than VHDs, or shrink the max size of the VHDs accordindly."`n }

Read-Host -Prompt "Press Enter to exit"