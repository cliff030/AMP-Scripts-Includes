. "\\AMP\Support\Scripts\includes\LoadSqlPs.ps1"
. "\\AMP\Support\Scripts\includes\DatabaseConfig.ps1"

$global:BankMarket = "001"
$global:ClientName = "Account Management Plus"
$global:FormatID = "03121"

$global:FilePath = "$env:USERPROFILE\Desktop"
$global:CheckRunID = 1749

try
{
    LoadSqlPs
}
catch [Exception]
{
    Write-Host -BackgroundColor Black -ForegroundColor Red $_.Exception.Message
    Write-Host -BackgroundColor Black
    Exit
}

function ConstructHeader($AccountNumber)
{
    try
    {
        $CurrentDate = (Get-Date)
        $FillerString = [String].Empty
        
        for($i = 0; $i -lt 128; $i++)
        {
            $FillerString += " "
        }
                
        $HeaderString = "H" + $BankMarket + $AccountNumber + $CurrentDate.ToString("MMddyyyy") + (SpaceFillString $ClientName 25) + $FormatID + $FillerString
    
        return $HeaderString
    }
    catch [Exception]
    {
        throw $_
    }
}

function ConstructDetailRow($AccountNumber,$Data)
{
    try
    {
        $FillerString = [String].Empty
        for($i = 0; $i -lt 20; $i ++)
        {
            $FillerString += " "
        }
        
        $CheckDate = [datetime]$Data."DateCreated"
        $CheckDate = $CheckDate.ToString("MMddyyyy")
        
        $CheckRunID = [string]$Data."CheckRunID"
    
        $Amount = [string](FormatAmount $Data."Amount")
        
        $OptionalData = SpaceFillString $CheckRunID 15
        
        if($Data."Name".Length -gt 50)
        {
            $CreditorName = $($Data."Name").SubString(0,50)
        }
        else
        {
            $CreditorName = SpaceFillString $Data."Name" 50
        }
        
        $PayeeLine2 = [String].Empty
        for($i = 0; $i -lt 50; $i++)
        {
            $PayeeLine2 += " "
        }

        $Row = "D" + $BankMarket + $AccountNumber + "I" + $CheckDate + (ZeroFillString ([string]$Data."CheckID") 10) + $Amount + $OptionalData + $FillerString + $CreditorName + $PayeeLine2
                
        return $Row
    }
    catch [Exception]
    {
        throw $_
    }
}

function ConstructTrailer($AccountNumber, $ToalAmount, $ToalNumberOfRecords)
{
    $Filler1 = [string].Empty
    for($i = 0; $i -lt 7; $i++)
    {
        $Filler1 += " "
    }
    
    $Filler2 = [string].Empty
    for($i = 0; $i -lt 137; $i++)
    {
        $Filler2 += " "
    }
    
    $TotalAmount = FormatAmount $ToalAmount
    

    $Trailer = "T" + $BankMarket + $AccountNumber + $Filler1 + (ZeroFillString ([string]$ToalNumberOfRecords) 10) + $TotalAmount + $Filler2
    
    return $Trailer
}

function GetChecks($CheckRunID)
{
    $sql = "SELECT DISTINCT chk.CheckID, chk.DateCreated, chk.Amount, cr.Name, chk.CheckRunID FROM Checks AS chk INNER JOIN Creditors AS cr ON cr.CreditorID = chk.CheckID WHERE chk.CheckRunID = $CheckRunID"
    
    $Result = Invoke-Sqlcmd -Query "$Sql" -ServerInstance $DSN -Database $DB
    
    return $Result
}

function FormatAmount($Amount)
{
    [string]$AmountString = [string]$Amount
    
    $AmountString = $AmountString.Replace(".","")
    
    try
    {    
        $AmountString = ZeroFillString $AmountString 12
    
        return $AmountString
    }
    catch [Exception]
    {
        throw $_
    }
}

function ZeroFillString($String,$ExpectedLength)
{
    if($String.Length -gt $ExpectedLength)
    {
        throw "The string $String is more than $ExpectedLength characters long."
    }
    elseif($String.Length -lt $ExpectedLength)
    {
        $i = $String.Length
        
        while($i -lt $ExpectedLength)
        {
            $String = "0" + $String
            $i++
        }
    }
    
    return $String
}

function SpaceFillString($String,$ExpectedLength)
{
    if($String.Length -gt $ExpectedLength)
    {
        throw "The string $String is more than $ExpectedLength characters long."
    }
    elseif($String.Length -lt $ExpectedLength)
    {
        $i = $String.Length
        
        while($i -lt $ExpectedLength)
        {
            $String = $String + " "
            $i++
        }
    }
    
    return $String
}

$AccountNumber = ZeroFillString "1215505027" 10

try
{
    SelectCompany
    
    $Filename = "PNC Checks " + $DB + "_" + (Get-Date).ToString("yyyy.MM.dd") + ".txt"

    $Header = ConstructHeader $AccountNumber
    
    $Checks = GetChecks $CheckRunID
        
    $Details = [string].empty
    
    $TotalAmount = [decimal]0.00
    $TotalNumberOfRecords = $Checks.Count
    
    for($i = 0; $i -lt $Checks.Count; $i++)
    {
        $Details += (ConstructDetailRow $AccountNumber $Checks[$i])
        
        $Details += "`r`n"
        
        $TotalAmount += $Checks[$i]."Amount"
    }
    
    $Trailer = ConstructTrailer $AccountNumber $TotalAmount $TotalNumberOfRecords
    
    $FileString = $Header + "`r`n" + $Details + $Trailer
        
    $FileString | Out-File "$FilePath\$FileName"   
}
catch [Exception]
{
    Write-Host $_.Exception.ToString()
}