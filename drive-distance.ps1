class CWApiRestSession
{
    [string] $Domain;
    [string] $CompanyName;
    [string] $PublicKey;
    [string] $PrivateKey;
    [string] $CodeBase;
    [string] $BaseUrl;
    [hashtable] $Header;
    [string] $ApiVersion = "3.0";
    [bool] $OverrideSSL = $false;

    CWApiRestSession ([string] $domain, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.Domain      = $domain;
        $this.CompanyName = $companyName;
        $this.PublicKey   = $publicKey;
        $this.PrivateKey  = $privateKey;

        if (!$this._setCodeBase())
        {
           throw
        }

        $this._buildBaseUri();
        $this._buildHttpHeader();
    }

    CWApiRestSession ([string] $domain, [string] $companyName, [string] $publicKey, [string] $privateKey, [bool] $overrideSSL)
    {
        $this.Domain      = $domain;
        $this.CompanyName = $companyName;
        $this.PublicKey   = $publicKey;
        $this.PrivateKey  = $privateKey;
        $this.OverrideSSL = $overrideSSL;

        if (!$this._setCodeBase())
        {
           throw
        }

        $this._buildBaseUri();
        $this._buildHttpHeader();
    }

    hidden [boolean] _setCodeBase ()
    {
        $companyInfoRaw = Invoke-WebRequest -Uri $([String]::Format("https://{0}/login/companyinfo/{1}", $this.Domain, $this.CompanyName)) -UseBasicParsing;
        $companyInfo = ConvertFrom-Json -InputObject $companyInfoRaw;

        $this.CodeBase = $companyInfo.Codebase;

        return $true;
    }

    hidden [void] _buildBaseUri ()
    {
        $this.BaseUrl = [String]::Format("https://{0}/{1}apis/{2}", $this.Domain, $this.CodeBase, $this.apiVersion);
    }

    hidden [void] _buildHttpHeader ()
    {
        $this.Header = [hashtable] @{
            "Authorization"    = $this._createCWAuthenticationString();
            "Accept"           = "application/vnd.connectwise.com+json;";
            "Type"             = "application/json";
        }

        if ($this.OverrideSSL)
        {
            $this.Header.Add("x-cw-overridessl", "True");
        }
    }

    hidden [string] _createCWAuthenticationString ()
    {
        [string] $encodedString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}+{1}:{2}" -f $this.CompanyName, $this.PublicKey, $this.PrivateKey)));
        return [String]::Format("Basic {0}", $encodedString);
    }

}

function Set-CWSession
{
    [CmdLetBinding()]
    [OutputType("CWApiRestSession", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='Normal', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='Normal', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [switch]$OverrideSSL
    )
    
    Begin
    {
        [CWApiRestSession] $cwSession = $null;
        
        if (!$OverrideSSL)
        {
            $cwSession = [CWApiRestSession]::New($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        else 
        {
            $cwSession = [CWApiRestSession]::New($Domain, $CompanyName, $PublicKey, $PrivateKey, $true);
        }
    }
    Process
    {
        [PSObject]$Script:CWSession = $cwSession
        $cwSession;
    }
    End
    {
        # do nothing here
    }    
}

function Test-CWSession
{
    [CmdLetBinding()]
    [OutputType("boolean", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Session = $script:CWSession
    )
    
    Begin
    {
        # get the service
        $cwApiSvc = $null;
        if ($Session -ne $null)
        {
            $cwApiSvc = [CWApiRestClientSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }

    }
    Process
    {
        return $cwApiSvc.TestConnection();
    }
    End
    {
        # do nothing here
    }    
}

function Get-CWCompany
{
    
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    [OutputType("PSObject[]", ParameterSetName="Identifier")]
    [OutputType("PSObject[]", ParameterSetName="Name")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32[]]$ID,
        [Parameter(ParameterSetName='Identifier', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Identifier,
        [Parameter(ParameterSetName='Name', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,
        [Parameter(ParameterSetName='Query', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Identifier', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Name', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Position=1, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Property,
        [Parameter(ParameterSetName='Identifier', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Name', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateRange(1, 1000)]
        [uint32]$SizeLimit = 100,
        [Parameter(ParameterSetName='Identifier')]
        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='Query')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Identifier', Mandatory=$false)]
        [Parameter(ParameterSetName='Name', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Session = $script:CWSession
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [string]$OrderBy = [String]::Empty;
        
        # get the service
        $CompanySvc = $null;
        if ($Session -ne $null)
        {
            $CompanySvc = [CwApiCompanySvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
        
        [uint32] $companyCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter) -or ![String]::IsNullOrWhiteSpace($Identifier) -or ![String]::IsNullOrWhiteSpace($Name))
        {
            if (![String]::IsNullOrWhiteSpace($Identifier))
            {
                $Filter = "identifier='$Identifier'";
                if ([RegEx]::IsMatch($Identifier, "\*"))
                {
                    $Filter = "identifier like '$Identifier'";

                }
                Write-Verbose "Created a Filter String Based on the Identifier Value ($Identifier): $Filter";
            }
            elseif (![String]::IsNullOrWhiteSpace($Name))
            {
                $Filter = "name='$Name'";
                if ($Name -contains "*")
                {
                    $Filter = "name like '$Name'";
                }
                Write-Verbose "Created a Filter String Based on the Identifier Value ($Identifier): $Filter";
            }
            
            $companyCount = $CompanySvc.GetCompanyCount($Filter);
            Write-Debug "Total Count Company using Filter ($Filter): $companyCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Company Count Excess SizeLimit; Setting Company Count to the SizeLimit: $SizeLimit"
                $companyCount = [Math]::Min($companyCount, $SizeLimit);
            }
            
            $pageCount = [Math]::Ceiling([double]($companyCount / $MAX_ITEMS_PER_PAGE));
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Companies Per Pages): $pageCount";
        } # end if for filter/identifier check
        
        #specify the ordering
        if ($Descending)
        {
            $OrderBy = " id desc";
        }
        
        # determines if to select all fields or specific fields
        [string[]] $Properties = $null;
        if ($null -ne $Property)
        {
            if (!($Property.Length -eq 1 -and $Property[0].Trim() -ne "*"))
            {
                # TODO add parser for valid fields only
                $Properties = $Property;
            }
        }
    }
    Process
    {
        
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if (![String]::IsNullOrWhiteSpace($Filter) -or ![String]::IsNullOrWhiteSpace($Identifier))
            {
                
                if ($null -ne $companyCount -and $companyCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $companyCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }
                
                Write-Debug "Requesting Company IDs that Meets this Filter: $Filter";
                $queriedCompanies = $CompanySvc.ReadCompanies($Filter, $Properties, $OrderBy, $pageNum, $itemsPerPage);
                [psobject[]] $Companies = $queriedCompanies;
                
                foreach ($Company in $Companies)
                {
                    $Company;
                }
                
            } 
            else 
            {
                
                Write-Debug "Retrieving ConnectWise Companies by Company ID"
                foreach ($CompanyID in $ID)
                {
                    Write-Verbose "Requesting ConnectWise Company Number: $CompanyID";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $CompanySvc.ReadCompany([uint32] $CompanyID);
                    }
                    else 
                    {
                        $CompanySvc.ReadCompany($CompanyID, $Properties);
                    }
                }
                           
            } #end if
            
        } #end foreach for pagination   
    }
    End
    {
        # do nothing here
    }
}


Set-CWSession -Domain "api-na.myconnectwise.net" -CompanyName "415Group" -PublicKey "tIl005okznlOwTuZ" -PrivateKey "xcfHGDF49ZMiUqsI"

Get-CWCompany -Identifier "415 Group" -Server $CWServer

$client = "Polymer Packaging"
$address =
$toRequest = 'https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=415+Group,+4300+Munson+St+NW,+Canton,+OH+44718&destinations=Polymer+Packaging,+Inc.,+Navarre+Rd+SE,+Massillon,+OH8&key=AIzaSyC62I9KqFauim288FePMP8B-HDjxGzezio'
$fromRequest = 'https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=Polymer+Packaging,+Inc.,+Navarre+Rd+SE,+Massillon,+OH&destinations=415+Group,+4300+Munson+St+NW,+Canton,+OH+44718&key=AIzaSyC62I9KqFauim288FePMP8B-HDjxGzezio'

$toMilesObject = Invoke-WebRequest $toRequest |
ConvertFrom-Json |
Select -expand rows |
Select -expand elements |
Select -expand distance

$fromMilesObject = Invoke-WebRequest $fromRequest |
ConvertFrom-Json |
Select -expand rows |
Select -expand elements |
Select -expand distance

$toMiles = $toMilesObject.text -replace ' mi'
$fromMiles = $fromMilesObject.text -replace ' mi'

$miles = [decimal]$toMiles + [decimal]$fromMiles


Write-Host From 415 Group to $client and back is $miles