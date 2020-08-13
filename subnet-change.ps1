Invoke-Command -ComputerName (Get-Content -Path C:\MyServers.txt) {
    $ip = $(Get-NetIPAddress | Where-Object {$_.IPAddress -like '192.168.192.*'}).IPAddress
    $interface = $(Get-NetIPAddress | Where-Object {$_.IPAddress -like '192.168.192.*'}).InterfaceIndex
    $subnet = 23

    Write-Host ---------------------------------------------
    Write-Host
    Write-Host Connected to $env:COMPUTERNAME

    Write-Host
    Write-Host Current IP: $ip
    Write-Host Current Subnet: $(Get-NetIPAddress | Where-Object {$_.IPAddress -like '192.168.192.*'}).PrefixLength

    Write-Host
    Write-Host Changing subnet prefix from $(Get-NetIPAddress | Where-Object {$_.IPAddress -like '192.168.192.*'}).PrefixLength to $subnet...

    Set-NetIPAddress -InterfaceIndex $interface -IPAddress $ip -PrefixLength $subnet

    Write-Host
    Write-Host New IP: $ip
    Write-Host New Subnet: $(Get-NetIPAddress | Where-Object {$_.IPAddress -like '192.168.192.*'}).PrefixLength
    Write-Host ---------------------------------------------
} -Credential (Get-Credential -Credential IRONROCK\415Group)