ForEach ($server in Get-Content "\\IRC-FS\415Group`$\Documentation\Server-List.txt")
{
	Get-NetConnectionProfile -CimSession "$server"
}