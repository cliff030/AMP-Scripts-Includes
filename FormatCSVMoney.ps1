# Any result returned by SQL Server Powershell extensions that is not NULL is automatically converted to a string. 
# Unfortunately, when SQL server money types are converted to strings there are 4 digits after the decimal instead of two.
# This function ensures that there are only two digits after the decimal
function FormatCSVMoney($Value) 
{
    #$Value = ([decimal]$Value)
    
    $Value = [system.math]::Round($Value,2)
        
    #return ([string]$Value)
   
    
    return $Value
    
    <#
    
    $value_string = [string]$value
    
    $value = $value_string.split(".")
    
    if($value.count -gt 1) {
        $value_string = [string]$value[0] + "." + $value[1].substring(0,2)
    } else {
        $value_string = $value[0]
    }
    
    return $value_string
    #>
}