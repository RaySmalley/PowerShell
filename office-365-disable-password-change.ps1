$Users = Get-MsolUser
$Users | Foreach-Object {
    Set-MsolUserPassword -userPrincipalName $_.UserPrincipalName -ForceChangePassword $False
}