. "\\AMP\Support\Scripts\includes\ADUser Functions.ps1"

function CreateAMPUser($UserName=$null,$Password=$null,$FirstName=$null,$LastName=$null,$email=$null)
{
    if(CheckCurrentUserPermissions -eq $true)
    {
        try
        {
            $OU = "OU=AMP Users,DC=accountmanagementplus,DC=com"
            
            if($UserName -ne $null -and $UserName -ne [String]::Empty)
            {
                if( (CheckIfADUserExists $UserName $OU) -eq $true)
                {
                    throw "The user $UserName already exists."
                }
            }
            
            if($Password -eq $null -or $Password -eq [String]::Empty)
            {
                $Password = "spring2011"
            }
            
            $Password = (ConvertTo-SecureString $Password -AsPlainText -force)
            
            $User = SetADUser $OU "AMP" $UserName $FirstName $LastName $email
            
            New-ADUser -Path $OU -Enabled $true -AccountExpirationDate $null -SamAccountName $User."SamAccountName" -GivenName $User."FirstName" -SurName $User."LastName" -DisplayName $User."FullName" -Name $User."FullName" -AccountPassword $Password -ChangePasswordAtLogon $true -UserPrincipalName ($User."SamAccountName" + "@accountmanagementplus.com") -EmailAddress $User."Email"
            
            Add-ADGroupMember -Identity "AMP Users" $User."SamAccountName"
                    
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