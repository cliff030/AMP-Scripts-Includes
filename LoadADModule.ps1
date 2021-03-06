function LoadADModule()
{
    if( -not (Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}))
    {
        write-host "The Active Directory powershell module is not installed. Please contact your administrator."
        Read-Host "Press enter to exit: "
        Exit
    }
    else
    {
        Import-Module ActiveDirectory
    }
}