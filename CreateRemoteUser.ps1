. "\\AMP\Support\Scripts\includes\DatabaseConfig 2.0.ps1"
. "\\AMP\Support\Scripts\includes\ADUser Functions.ps1"

function SetUser($OU) {
    $i = 0
    
    while($i -eq 0) {
        $Username = Read-Host -Prompt "Enter the username: "
        $Username = $Username -replace "^AMP\\"
        
        $SamAccountName = ($Username -Replace " ").ToUpper()
        $FirstName = ($Username -Split " ")[0]
        $LastName = ($Username -Split " ")[1]
    
        if( (CheckIfADUserExists $SamAccountName $OU) -eq $true) {
            Write-Host "This user already exists!"
        } else {
            $i++
        }
    }
    
    $User = @{"SamAccountName"=$SamAccountName;"FirstName"=$SamAccountName;"LastName"=$null;"FullName"=$SamAccountName}
    
    Return $User
}


function SetOU {
    $OU = "ou=" + $global:Company."ShortName" + ",ou=Remote Users,dc=accountmanagementplus,dc=com"
    
    return $OU
}

function SetPassword {
    switch($Company."ShortName") {
        "Select" {
            $password = "docusignisfun"
        }
        "Liberty" {
            $password = "4mplF1n"
        }
        "Karma" {
            $password = "karma2014"
        }
        "FFN" {
            $password = "4mplF1n"
        }
        default {
            throw "Invalid company selected!"
        }
    }
    
    $password = (ConvertTo-SecureString $password -AsPlainText -force)
    
    return $password
}

function SetUserProfile {
    $UserProfile = "\\AMP\" + $Company."Name" + '\User Profiles\%username%'
    
    Return $UserProfile
}

function CreateRemoteUser
{
    if(CheckCurrentUserPermissions -eq $true)
    {
        try
        {
            SelectCompany

            $Group = (Get-ADGroup -Identity $global:Company."Group")
            $PrimaryGroupID = $Group.SID.Value.Substring($Group.SID.Value.LastIndexOf('-')+1)

            $OU = SetOU

            $Password = SetPassword

            $UserProfile = SetUserProfile

            $User = SetADUser $OU "Remote"

            New-ADUser -Path $OU -Enabled $true -AccountExpirationDate $null -SamAccountName $User."SamAccountName" -GivenName $User."FirstName" -DisplayName $User."FullName" -Name $User."FullName" -PasswordNeverExpires $true -AccountPassword $Password -ChangePasswordAtLogon $false -Profile $UserProfile -UserPrincipalName ($User."SamAccountName" + "@accountmanagementplus.com")

            Add-ADGroupMember -Identity "CSOFT Remote" $User."SamAccountName"
            Add-ADGroupMember -Identity $Company."Group" $User."SamAccountName"
            
            $User.Add("Success",$true)
        }
        catch 
        {
            if($user -eq $null)
            {
                $user = @{"Success"=$false}
            }
            else
            {
                $User.Add("Success",$false)
            }
            
            Write-Host $_.Exception.Message
        }
        finally
        {
            return $User
        }
    }
    else
    {
        $User = @{"Success"=$false}
        
        Write-Host "You do not have the necessary permissions to create a user account. Please contact your administrator."
        
        return $User
    }
}