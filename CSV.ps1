. "\\AMP\Support\Scripts\includes\CreateCSVString.ps1"
function WriteCSVFile($CSVString,$Filename)
{
    $CSV = [System.Text.Encoding]::ASCII.GetBytes($CSVString)
    
    $fileStream = New-Object System.IO.FileStream($Filename, [System.IO.FileMode]::OpenOrCreate)
    $fileStream.Write($CSV, 0, $CSV.Length)
    $fileStream.Close()
}