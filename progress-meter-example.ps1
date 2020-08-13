###############################################################################
# NAME:      ProgressBarTest.ps1
# AUTHOR:    Bobby Crotty, Credera
# DATE:      3/31/2016
#
# This script demonstrates the functionality and options of progress bars.
#
# VERSION HISTORY:
# 1.0    3/31/2016    Initial Version
###############################################################################
 
###########################################
################## SETUP ##################
###########################################
 
# Progress Bar Variables
$Activity             = "Creating Administrator Report"
$UserActivity         = "Processing Users"
$Id                   = 1
 
# Progress Bar Pause Variables
$ProgressBarWait      = 1500 # Set the pause length for operations in the main script
$ProgressBarWaitGroup = 250 # Set the pause length for operations while processing groups
$ProgressBarWaitUser  = 50 # Set the pause length for operations while processing users
$AddPauses            = $true # Set to $true to add pauses that help highlight progress bar functionality
 
# Simple Progress Bar
$Task                 = "Setting Initial Variables"
Write-Progress -Id $Id -Activity $Activity -Status $Task
if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWait }
 
# Complex Progress Bar
$TotalSteps           = 4 # Manually count the total number of steps in the script
$Step                 = 1 # Set this at the beginning of each step
$StepText             = "Setting Initial Variables" # Set this at the beginning of each step
$StatusText           = '"Step $($Step.ToString().PadLeft($TotalSteps.Count.ToString().Length)) of $TotalSteps | $StepText"' # Single quotes need to be on the outside
$StatusBlock          = [ScriptBlock]::Create($StatusText) # This script block allows the string above to use the current values of embedded values each time it's run
 
# Groups Script Block
$Task                 = "Creating Progress Bar Script Block for Groups"
Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -CurrentOperation $Task -PercentComplete ($Step / $TotalSteps * 100)
if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWait }
 
$CurGroupText         = '"Group $($CurGroup.ToString().PadLeft($Groups.Count.ToString().Length)) of $($Groups.Count) | $($Group.Name)"'
$CurGroupBlock        = [ScriptBlock]::Create($CurGroupText)
 
# Users Script Block
$Task                 = "Creating Progress Bar Script Block for Users"
Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -CurrentOperation $Task -PercentComplete ($Step / $TotalSteps * 100)
if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWait }
 
$CurUserText          = '"User $($CurUser.ToString().PadLeft($Users.Count.ToString().Length)) of $($Users.Count) | $($_.SamAccountName.PadRight($UsersNameLengthMax+3))"'
$CurUserBlock         = [ScriptBlock]::Create($CurUserText)
 
# Filter Variables
$GroupFilter          = "*admin*" # Report on groups that match this filter
 
 
###########################################
################## SCRIPT #################
###########################################
 
$Step = 2
$StepText = "Getting Groups"
$Task = "Running Get-ADGroup"
Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -CurrentOperation $Task -PercentComplete ($Step / $TotalSteps * 100)
Import-Module ActiveDirectory
$Groups = Get-ADGroup -Filter {Name -like $GroupFilter}
if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWait }
$Task = "Pausing After Running Get-ADGroup"
Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -CurrentOperation $Task -PercentComplete ($Step / $TotalSteps * 100)
if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWait }
 
 
$Step = 3
$StepText = "Processing Groups"
Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -CurrentOperation " " -PercentComplete ($Step / $TotalSteps * 100) # CurrentOperation needs to have a space to keep vertical spacing
 
$CurGroup = 0
foreach ($Group in $Groups) {
    $CurGroup++
    $CurGroupPercent = $CurGroup / $Groups.Count * 100
    $Task = "Getting Group Members"
    Write-Progress -Id ($Id+1) -Activity $Activity -Status (& $CurGroupBlock) -CurrentOperation $Task -PercentComplete $CurGroupPercent -ParentId $Id
    $Users = @($Group | Get-ADGroupMember -Recursive)
    if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWaitGroup}
 
    $Task = "Calculating Username Max Length"
    Write-Progress -Id ($Id+1) -Activity $Activity -Status (& $CurGroupBlock) -CurrentOperation $Task -PercentComplete $CurGroupPercent -ParentId $Id
    $UsersNameLengthMax = $Users | Select -ExpandProperty SamAccountName | Select -ExpandProperty Length | Measure -Maximum | Select -ExpandProperty Maximum
    if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWaitGroup}
 
    Write-Progress -Id ($Id+1) -Activity $Activity -Status (& $CurGroupBlock) -PercentComplete $CurGroupPercent -ParentId $Id
 
    $CurUser = 0
    $Users | %{
        $CurUser++
        $UserPercentProcessed = $CurUser / $Users.Count * 100
        $Task = "Getting User Details"
        Write-Progress -Id ($Id+2) -Activity $UserActivity -Status ((& $CurUserBlock) + $Task) -PercentComplete $UserPercentProcessed -ParentId ($Id+1)
        if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWaitUser}
        $User = $_ | Get-ADUser -Properties PasswordLastSet
 
        $Task = "Collating User Details"
        Write-Progress -Id ($Id+2) -Activity $UserActivity -Status ((& $CurUserBlock) + $Task) -PercentComplete $UserPercentProcessed -ParentId ($Id+1)
        if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWaitUser}
        $_ | Select Name,SamAccountName,@{Name="PasswordAge"; Expr={((Get-Date) - $_.PasswordLastSet).Days}}
    } | Add-Member -MemberType NoteProperty -Name "Group"  -Value $Group.Name -PassThru | Export-Csv "$env:USERPROFILE\Downloads\Admins.csv" -NoTypeInformation -Append
    Write-Progress -Id ($Id+2) -Activity $Activity -Completed
}
 
$Step = 4
$StepText = "Finishing Script"
$Task = "Completing Progress Bars"
Write-Progress -Id $Id -Activity $Activity -Status (& $StatusBlock) -CurrentOperation $Task -PercentComplete ($Step / $TotalSteps * 100)
if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWait }
Write-Progress -Id ($Id+1) -Activity $Activity -Completed
if ($AddPauses) { Start-Sleep -Milliseconds $ProgressBarWait }