Function PassGen ([Int]$Size = 10, [Char[]]$CharSets = "ULNS", [Char[]]$Exclude) {
    $Chars = @(); $TokenSet = @()
    If (!$TokenSets) {$Global:TokenSets = @{
        U = [Char[]]'ABCDEFGHJKLMNPQRSTUVWXYZ'
        L = [Char[]]'abcdefghijkmnopqrstuvwxyz'
        N = [Char[]]'23456789'
        S = [Char[]]'!@#$%^&*()-+=.:;<>?_'
    }}
    $CharSets | ForEach {
        $Tokens = $TokenSets."$_" | ForEach {If ($Exclude -cNotContains $_) {$_}}
        If ($Tokens) {
            $TokensSet += $Tokens
            If ($_ -cle [Char]"Z") {$Chars += $Tokens | Get-Random}             # Character sets defined in upper case are mandatory
        }
    }
    While ($Chars.Count -lt $Size) {$Chars += $TokensSet | Get-Random}
    ($Chars | Sort-Object {Get-Random}) -Join ""                                # Mix the (mandatory) characters and output string
}; Set-Alias pg PassGen