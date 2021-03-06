$global:DSN = "tcp:AMP-DC,1433"

$global:Companies = @(
    (New-Object PSObject -Property @{
        "Name"="Select Financial";
        "DB"="CSDATA9";
        "MenuOption"="1";
    }),
    (New-Object PSObject -Property @{
        "Name"="Liberty Financial";
        "DB"="CSDATA9_INC";
        "MenuOption"="2";
    }),
    (New-Object PsObject -Property @{
        "Name"="First Financial";
        "DB"="CSDATA9_FFN";
        "MenuOption"="3";
    })
)

$global:DB = $null
$global:Company = $null

# Needed to initialize the global variables $DB and $Company, which specify the database and company name to use.
function SetCompany($DB,$Company)
{
    Set-Variable -Scope Global -Name DB -Value $Local:DB
    Set-Variable -Scope Global -Name Company -Value $Local:Company
}

# Prompts the user to pick which company/database is to be used.
# Once the user selects a valid options the global variables $DB and $Company will be set by the SetCompany function.
# Currently, the only options are Select Financial (CSDATA8) and Liberty Financial (CSDATA8_INC)
function SelectCompany()
{
    $k = 0    
    while($k -eq 0)
    {
        $OptionList = "Database options:`n"
        foreach($Company in $Companies)
        {
            $OptionList += $Company."MenuOption" + ". " + $Company."Name" + "`n"
        }
    
        Write-Host $OptionList
        $Selection = Read-host "Select your database"
        
        $match = $false
        for($i = 0; $i -lt $Companies.Length; $i++)
        {
            if($Companies[$i]."MenuOption" -eq $Selection)
            {
                $match = $true
                break
            }
        }
        
        if($match -eq $true)
        {
            $k++
            SetCompany $Companies[$i]."DB" $Companies[$i]."Name"
        }
        else
        {
            Write-Host "Invalid selection!"
        }
    }
}