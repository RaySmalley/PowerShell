# Script to repair OMNI-PACS2016 VM after failed snapshots occur


# Restart Hyper-V Virtual Machine Management service
Restart-Service -Name vmms

# Shut down VM
Write-Host "Shutting down OMNI-PACS2016..."
Stop-VM -Name OMNI-PACS2016
Write-Host ""

# Merge all AVHDX files to parent VHDX
foreach ($avhdx in (Get-ChildItem "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\*.avhdx")) {
    Write-Host "Merging $avhdx.Name to parent VHDX..."
    Merge-VHD -Path $avhdx.FullName -Force
}
Write-Host "Done merging."`n

# Clean up Veeam files
#Remove-Item -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\*.mrt" -Force
#Remove-Item -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\*.rct" -Force

# Remove all existing AVHDX files
Write-Host "Removing all existing VHDs for OMNI-PACS2016 VM..."`n
Get-VMHardDiskDrive -VMName OMNI-PACS2016 | Remove-VMHardDiskDrive

# Add parent VHDX files back to VM
Write-Host "Adding parent VHDX files back to OMNI-PACS2016 VM..."`n
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-E.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-F.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-G.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-I.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-J.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-K.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-L.vhdx"
Add-VMHardDiskDrive -VMName OMNI-PACS2016 -Path "E:\VMs\OMNI-PACS2016\Virtual Hard Disks\OMNI-PACS2016-M.vhdx"
Write-Host "Done."