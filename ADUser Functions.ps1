function CheckIfADUserExists($Username,$OU) {
    try {
        $User = (Get-ADUser -SearchBase $OU -Filter {SamAccountName -eq $Username})
        
        if($User -ne $null) {
            return $true
        } else {
            return $false
        }
        
        return $true
    }
    catch [exception] {
        return $false
    }
}

function SetADUser {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$OU,
        [Parameter(Mandatory=$True,Position=2)]
        [string]$UserType,
        [Parameter(Mandatory=$False,Position=3)]
        [string]$username,
        [Parameter(Mandatory=$False,Position=4)]
        [string]$firstname,
        [Parameter(Mandatory=$False,Position=5)]
        [string]$lastname,
        [Parameter(Mandatory=$False,Position=6)]
        [string]$email
    )
    
    if($username -eq $null -or $username -eq [String]::Empty)
    {    
        $i = 0
        
        while($i -eq 0) {
            
                        
            if($UserType -eq "Remote")
            {
                $Username = Read-Host -Prompt "Enter the username: "
                $Username = $Username -replace "^AMP\\"
            
                $SamAccountName = ($Username -Replace " ").ToUpper()
                $firstname = $SamAccountName
                $lastname = $null
                $email = $null
            }
            else
            {                
                if($firstname -eq $null -or $firstname -eq [String]::Empty)
                {
                    $firstname = Read-Host -Prompt "Enter the user's first name: "
                }
                if($lastname -eq $null -or $lastname -eq [String]::Empty)
                {
                    $lastname = Read-Host -Prompt "Enter the user's last name: "
                }
                
                $Username = $firstname.SubString(0,1).ToLower() + $lastname.ToLower()
            
                $SamAccountName = $Username
                
                $email = $firstname.ToLower() + $lastname.SubString(0,1).ToLower() + "@ampaccount.com"             
                
                if($email -eq $null -or $email -eq [String]::Empty)
                {
                    $email = Read-Host -Prompt "Enter the user's e-mail address: "
                }
            }
        
            if( (CheckIfADUserExists $SamAccountName $OU) -eq $true) {
                Write-Host "This user already exists!"
            } else {
                $i++
            }
        }
    }
    
    $FullName = $FirstName + " " + $LastName
    
    $User = @{"SamAccountName"=$SamAccountName;"FirstName"=$firstname;"LastName"=$lastname;"Email"=$email;"FullName"=$FullName}
    
    Return $User
}


function CheckCurrentUserPermissions()
{
    $RequiredPermissions = @("GenericAll", "CreateChild, DeleteChild", "ReadProperty, WriteProperty")

    $username = $env:username

    $user = Get-ADUser -Filter {samAccountName -eq $username}

    $groups = @()
    Get-ADPrincipalGroupMembership $user.samAccountName | Select Name | ForEach-Object {$groups += "AMP\" + $_.Name}

    $ACLs = Get-ACL -Path "AD:\OU=Remote Users,DC=accountmanagementplus,DC=com" | Select-Object -ExpandProperty Access | Where-Object {$_.AccessControlType -eq "Allow" -and $RequiredPermissions -contains $_.ActiveDirectoryRights -and $groups -contains $_.IdentityReference.Value}

    $EffectiveACLs = @()
    foreach($ACL in $ACLs)
    {
        if($EffectiveACLs.Length -eq 0)
        {
            $EffectiveACLs += $ACL
        }
        else
        {
            $FoundACL = $false
        
            foreach($EffectiveACL in $EffectiveACLs)
            {
                if($EffectiveACL.ActiveDirectoryRights -eq $ACL.ActiveDirectoryRights)
                {
                    $FoundACL = $true
                    break
                }
            }
            
            if($FoundACL -eq $false)
            {
                $EffectiveACLs += $ACL
            }
        }
    }

    if($EffectiveACLs.Length -lt 3)
    {
        return $false 
    }
    else
    {
        return $true
    }
}