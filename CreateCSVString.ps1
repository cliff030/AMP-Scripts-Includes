<#
# Receives an array of System.DataRow (usually returned by the SQL Server Powershell module)
# Returns a CSV-formatted string that can be written to a file or displayed on screen
#>

. "\\AMP\Support\Scripts\includes\FormatCSVString.ps1"

# This function removes all non-ASCII characters from the input string for certain ACH processors who are stuck in 1994.
function ConvertToASCII($String)
{
    # u0000 - u007F = Unicode characters 0 - 127 (aka the ASCII characters).
    # This replaces unicode characters outside this range with an empty value.
    
    $String = [regex]::Replace([string]$String, [regex]'[^\u0000-\u007F]', [string]::empty)
   
    return $String
}

<#
# This function currently has the following options:
# Unicode (boolean) - Specifies whether or not the string can have unicode characters in it. Default: true
# Debug (boolean) - Specifies whether or not we are debugging the string. This currently only affects which return character is used for new lines. Default: false
#>
function CreateCSVString($DataSet,$Options=@{"Unicode"=$true;"Debug"=$false;"Header"=$true;"DateFormat"="d"})
{
    $Settings = New-Object PsObject -Property $Options
    
    $ReturnChar = @{$true="`r`n";$false="`r`n"}[$Settings."Debug" -eq $true]
    
    # Initialize the CSVString variable, which will ultimately be used to write the completed CSV to a file
    $CSVString = [string]::empty

    # After grabbing the value for a column in each row we need to terminate the string with either a comma (,) or a return character (`r for files and `n for debugging with Write-Host). The number of columns in the row affects this decision
    $ColumnCount = $DataSet[0].Table.Columns.Count

    # Optionally, loop through the names of each column in order to create the header row of our CSV.
    if($Settings."Header" -eq $true)
    {
        foreach($Col in $DataSet[0].Table.Columns)
        {        
            $String = FormatCSVString $Col.ColumnName
        
            if($Settings."Unicode" -eq $false)
            {
                $String = ConvertToASCII $String
            }
    
            $CSVString += $String
    
            # Add a comma to the string unless we're on the last column in which case it's time to insert a return character and move to the next row.
            if($Col.Ordinal -lt ($ColumnCount - 1) )
            {
                $CSVString += ","
            }
            else
            {
                $CSVString += $ReturnChar
            }
        }
    }

    # Same procedure as what we did for the header row with the addition of looping through each row of actual data.
    foreach($DataRow in $DataSet)
    {   
        foreach($Col in $DataRow.Table.Columns)
        {
            if($DataRow.$Col.GetType().Name -eq "DateTime")
            {
                $String = ($DataRow.$Col).ToString($Settings."DateFormat")
            }
            else
            {
                $String = $DataRow.$Col
            }
         
            $String = FormatCSVString $String
            
            if($Settings."Unicode" -eq $false)
            {
                $String = ConvertToASCII $String
            }
            
            $CSVString += $String
                    
            if( $Col.Ordinal -lt ($ColumnCount - 1) )
            {
                $CSVString += ","
            }
            else
            {
                $CSVString += $ReturnChar 
            }
        }
    }
    
    return $CSVString
}

# Formats phone numbers for suitable CSV inclusion
# Accepts numeric formatting strings only (such as the default string)
function FormatPhoneNumber($PhoneNumber, $PhoneNumberFormat = "{0:(###)###-####}")
{
    # Strip out all the non-numerical text
    $regex = '[^\d]'
    $re = New-Object -TypeName System.Text.RegularExpressions.Regex -ArgumentList $regex
    $PhoneNumber = $re.Replace($PhoneNumber,"")
    
    # If the string returned is the correct number of digits, then format it as (###)###-####
    if($PhoneNumber.Length -gt 11 -or $PhoneNumber.Length -lt 10)
    {
        $PhoneNumber = $null
    }
    else
    {
        if($PhoneNumber.Length -eq 11)
        {
            $PhoneNumber = $PhoneNumber.SubString(0,11)
        }
        
        # Temporarily make $PhoneNumber an int so String.Format will work correctly
        $PhoneNumber = [int]$PhoneNumber        
        $PhoneNumber = [System.String]::Format($PhoneNumberFormat, $PhoneNumber)
    }
    
    return $PhoneNumber
}