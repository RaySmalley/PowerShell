Get-ADUser -filter * -properties scriptpath, homedrive, homedirectory | ft Name, scriptpath, homedrive, homedirectory
(Get-ADUser -filter * -properties scriptpath).ScriptPath | Group