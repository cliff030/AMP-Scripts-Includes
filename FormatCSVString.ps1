# Receives any input
# Converts the input to a String, removes any commas, and wraps the string in double quotes (")
function FormatCSVString($String) 
{
    $String = ([string]$String).replace(",","")
    return '"' + $String + '"'
}