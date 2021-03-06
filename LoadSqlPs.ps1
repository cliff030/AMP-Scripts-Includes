function LoadSqlPs {
    #
	# Add the SQL Server Provider.
	#
	if ( (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -eq $null ) {
	    $ErrorActionPreference = "Stop"
	
	    $sqlpsreg="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"
	
	    if (Get-ChildItem $sqlpsreg -ErrorAction "SilentlyContinue") {
	        throw "SQL Server Provider for Windows PowerShell is not installed."
	    }
	    else {
            $item = Get-ItemProperty $sqlpsreg
            $sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)   
        
            if( (Get-PSSnapin -Registered | Select-String "SqlServerCmdletSnapin100") -eq $null ) {
                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
                
                if($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) {
                    $framework=$([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())
                    Set-Alias installutil "$($framework)installutil.exe"
                    cd $sqlpsPath
                    installutil $sqlpsPath\Microsoft.SqlServer.Management.PSSnapins.dll
                    installutil $sqlpsPath\Microsoft.SqlServer.Management.PSProvider.dll    
                } else {
                    throw "The SQL Server Powershell Snapins have not been registered. Please run the script as Administrator to register them."
                }
            }           
        }
	
	
	    #
	    # Set mandatory variables for the SQL Server provider
	    #
	    Set-Variable -scope Global -name SqlServerMaximumChildItems -Value 0
	    Set-Variable -scope Global -name SqlServerConnectionTimeout -Value 30
	    Set-Variable -scope Global -name SqlServerIncludeSystemObjects -Value $false
	    Set-Variable -scope Global -name SqlServerMaximumTabCompletion -Value 1000
	
	    #
	    # Load the snapins, type data, format data
	    #
	    Push-Location
	    cd $sqlpsPath
	    Add-PSSnapin SqlServerCmdletSnapin100
	    Add-PSSnapin SqlServerProviderSnapin100
	    Update-TypeData -PrependPath SQLProvider.Types.ps1xml 
	    update-FormatData -prependpath SQLProvider.Format.ps1xml 
	    Pop-Location
	}
}