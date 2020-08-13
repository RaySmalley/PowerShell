Set-ExecutionPolicy RemoteSigned

if (Get-PSSession) { Remove-PSSession $(Get-PSSession) }

$credsFile = "${env:\userprofile}\365creds.xml"

if (! (Test-Path $credsFile)) {
    $credsHash = @{
    #'Affinity' = Get-Credential -Message 'Enter Affinity credentials'
    #'Archer' = Get-Credential -Message 'Enter Archer credentials'
    'Brookwood' = Get-Credential -Message 'Enter Brookwood credentials'
    # 'Palace' = Get-Credential -Message 'Enter Palace Theatre credentials'
    # 'CapTape' = Get-Credential -Message 'Enter Capital Tape credentials'
    # 'CathChar' = Get-Credential -Message 'Enter Catholic Charities credentials'
    # 'Combi' = Get-Credential -Message 'Enter Combi credentials'
    # 'Eagle' = Get-Credential -Message 'Enter Eagle Reality credentials'
    # 'EB' = Get-Credential -Message 'Enter EB Display credentials'
    # 'FamPhys' = Get-Credential -Message 'Enter Family Physicians credentials'
    # 'Furey' = Get-Credential -Message 'Enter Furey credentials'
    # 'GDK' = Get-Credential -Message 'Enter GDK credentials'
    # 'HighMill' = Get-Credential -Message 'Enter High Mill credentials'
    # 'Hydrodec' = Get-Credential -Message 'Enter Hydrodec credentials'
    # 'JA' = Get-Credential -Message 'Enter Junior Achievement credentials'
    # 'LakeTown' = Get-Credential -Message 'Enter Lake Township credentials'
    # 'MartinPallet' = Get-Credential -Message 'Enter Martin Pallet credentials'
    # 'MCHair' = Get-Credential -Message 'Enter MC Hair credentials'
    # 'Mids' = Get-Credential -Message 'Enter Mids credentials'
    # 'MinDairy' = Get-Credential -Message 'Enter Minerva Dairy credentials'
    # 'OhioRet' = Get-Credential -Message 'Enter Ohio Retina credentials'
    # 'Polymer' = Get-Credential -Message 'Enter Polymer Packaging credentials'
    # 'Rices' = Get-Credential -Message 'Enter Rices Nursery credentials'
    # 'Roberts' = Get-Credential -Message 'Enter Roberts Medical credentials'
    # 'Selinsky' = Get-Credential -Message 'Enter Selinsky credentials'
    # 'SCF' = Get-Credential -Message 'Enter Stark Community credentials'
    # 'SDB' = Get-Credential -Message 'Enter Stark Dev Board credentials'
    # 'Tolloti' = Get-Credential -Message 'Enter Tolloti Pipe credentials'
    # 'TPM' = Get-Credential -Message 'Enter TPM credentials'
    # 'Troyer' = Get-Credential -Message 'Enter Troyer credentials'
    # 'Vail' = Get-Credential -Message 'Enter Vail credentials'
    }
$credsHash | Export-Clixml -Path $credsFile
}

$creds = Import-Clixml -Path $credsFile

$ruleName = "Creation of forwarding/redirect rule - custom 3"
$ruleEmail = "helpdesk@415group.com"

ForEach ($key in $creds.Keys) {
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $creds[$key] -Authentication Basic -AllowRedirection
 
    Import-PSSession $session -DisableNameChecking

    $alert = $null
    $alert = Get-ActivityAlert -Identity $ruleName -ErrorAction SilentlyContinue
    if (!$alert) {
        New-ActivityAlert -Name $ruleName -NotifyUser $ruleEmail -Type SimpleAggregation -Operation Set-Mailbox -Category ThreatManagement -Threshold 3 -TimeWindow 0 -Condition forwardTo -WhatIf | gm
    }

    $alert
    
    #Remove-PSSession $session
}