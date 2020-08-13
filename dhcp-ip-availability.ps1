# Clear arrays
$InUse = @()
$Free = @()
$Total = @()
$PercentageInUse = @()

# Get DHCP info
$DHCPinfo = netsh dhcp server show mibinfo
$InUseStr = @($DHCPinfo | Where-Object { $_ -match "No. of Addresses in use = " } | ForEach-Object { $_.Split("=")[-1].Trim( ).Trim(".").Trim(" ") })
$FreeStr = @($DHCPinfo | Where-Object { $_ -match "No. of free Addresses = " } | ForEach-Object { $_.Split("=")[-1].Trim( ).Trim(".").Trim(" ") })
$NumOfScopes = $InUseStr.Count

# Check for superscope
$IsNotSuperscope = netsh dhcp server show superscope | Where-Object { $_ -match "(null)" }

# Get percentage of IPs in use from each scope and store them in dynamically named variables
$i = 0
Do {
    $InUse += [int]$InUseStr[$i]
    $Free += [int]$FreeStr[$i]
    $Total += ($InUse[$i] + $Free[$i])
    $PercentageInUse += ($InUse[$i] / $Total[$i])*100
    $TempPIU = [Math]::Round($PercentageInUse[$i])
    $i++
	New-Variable -Name PercentageInUseScope$i -Value $TempPIU
} Until ($i -eq $NumOfScopes)

# If superscope is in use, report average in-use percentage
if ($IsNotSuperscope -ne "SuperScope    : (null)") {
    $PercentageInUseScope1 = [math]::Round((($InUse | Measure-Object -Sum).Sum) / (($Total | Measure-Object -Sum).Sum)*100)
    $PercentageInUseScope2 = 0
}