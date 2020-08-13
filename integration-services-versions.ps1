Get-ClusterGroup | Where-Object {($_.Name -notlike "Available Storage") -and ($_.Name -notlike "Cluster Group")} | Get-VM | Format-Table Name, IntegrationServicesVersion
pause