function GetBatchList($ACHBatchGroupID, $Sql)
{
    $Sql += " " + $ACHBatchGroupID

    $Result = Invoke-Sqlcmd -Query "$Sql" -ServerInstance $DSN -Database $DB
    
    # For whatever reason the SQL Server Powershell module leaves 4 digits after the decimal place when converting SQL server money data types to the System.decimal data type
    # ACH processors tend not to like that so we correct it
    foreach($Row in $Result)
    {
        foreach($Col in $Row.Table.Columns)
        {
            if($Row.$Col.GetType().Name -eq "decimal")
            {
                $Row.$Col = [System.Math]::Round($Row.$Col,2)
            }
        }
    }
    
    return $Result
}

function CheckBatchGroupID($ACHBatchGroupID)
{
    try
    {
        $ACHBatchGroupID = [int]$ACHBatchGroupID
    }
    catch
    {
        [System.Exception]
        return $false
    }

    $Sql = "SELECT COUNT(ACHBatchGroupID) FROM ACHBatchGroup WHERE ACHBatchGroupID = $ACHBatchGroupID"
    
    $Result = Invoke-Sqlcmd -Query "$Sql" -ServerInstance $DSN -Database $DB
    
    if($Result[0] -gt 0)
    {
        return $true
    }
    else
    {
        return $false
    }
}

# Prompts the user to enter the ACHBatchGroupID, and then returns the result (integer)
function SelectBatchGroup()
{
    $i = 0
    
    while($i -eq 0)
    {
        $ACHBatchGroupID = Read-Host "Enter Batch Group ID"
    
        if( (CheckBatchGroupID $ACHBatchGroupID) -ne $true)
        {
            Write-Host "Batch Group $ACHBatchGroupID does not exist!"
        }
        else
        {
            $i++
        }
    }
    
    return $ACHBatchGroupID
}