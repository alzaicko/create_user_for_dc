#   Generation Password
$dc_server = "<IP or hostname DC server>"   # You primary damain controller
$dc_domain = "<test.local>"                 # You domain
$dc_path = "<path to create user>"          # CN=Users,DC=test,DC=local
$mail_domain = "<exemple.com>"              # user@exemple.com

function genpass {
    [int] $len = 10
    [string] $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#`$^&%"
    $bytes = new-object "System.Byte[]" $len
    $rng = new-object System.Security.Cryptography.RNGCryptoServiceProvider
    $rng.GetBytes($bytes)
    $result = ""
    for( $i=0; $i -lt $len; $i++ ) {
    $result += $chars[ $bytes[$i] % $chars.Length ] 
    }
    if (($result -cmatch '[a-z]') -and ($result -cmatch '[A-Z]') -and ($result -match '\d') -and ($result.length -ge 8) -and ($result -match '!|@|#|%|^|&|$')) {
        $result
    }
    else {
        genpass
    }
}

#   Checking the password for cryptographic strength, if the password is entered by the user is also checking for a match.
function pass ($PasswordEntered, $PasswordEnteredNoSecure) {

    if (($PasswordEnteredNoSecure -cmatch '[a-z]') -and ($PasswordEnteredNoSecure -cmatch '[A-Z]') -and ($PasswordEnteredNoSecure -match '\d') -and ($PasswordEnteredNoSecure.length -ge 8) -and ($PasswordEnteredNoSecure -match '!|@|#|%|^|&|$')) {
        $ReEnteredPassword = Read-Host -AsSecureString "Confirm password"
        $ReEnteredPasswordNoSecure = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ReEnteredPassword))
        if ($PasswordEnteredNoSecure -ccontains $ReEnteredPasswordNoSecure) {
            return $ReEnteredPasswordNoSecure
        }
        else {
            Write-Host "Error. Passwords do not match. Try again." -ForegroundColor Red
            pass
        }
    }
    else {
        Write-Host "Password does not comply with security policy." -ForegroundColor Red
        $gen = Read-Host "Generated password? (y/n)"
        if ('y' -contains $gen) {
            $result1 = genpass $result
            return $result1
        }
        else {
            pass
        } 
    }
}
#   Getting username and check
function Name {
    $Name = Read-Host 'First Name'
    if ($Name.Length -ge 1) {
        return $Name
    }
    else {
        Write-Host "The field cannot be empty." -ForegroundColor Red    
        Name   
    }
}
#   Getting surname and check
function Surname {
    $Surname = Read-Host 'Last Name'
    if ($Surname.Length -ge 1) {
        return $Surname      
    }
    else {
        Write-Host "The field cannot be empty." -ForegroundColor Red    
        Surname 
    }
} 

function Admin {
    $Admin_login = Read-Host "Login domain admin"
    if ($Admin_login.Length -ge 1) {
        $usrexist=Get-ADUser  -filter {(SamAccountName -eq $Admin_login)} | Select-Object -ExpandProperty SamAccountName
        if ($usrexist -eq $Admin_login) {
            return $Admin_login
         }
         else {
            Write-Host "User does not exist" -ForegroundColor Red
            Admin 
         }   
    }
    else {
        Write-Host "The field cannot be empty." -ForegroundColor Red    
        Admin 
    }
} 

function usrcreate ($dc_server, $dc_path, $dc_domain, $mail_domain) {
    $Admin = Admin
    #   Getting username
    $Name = Name
    #   Getting surname
    $Surname = Surname
    #   Convert name and surname to login
    $AccountName = $name.ToLower() + '.' + $surname.ToLower()
    $samAccountName = $AccountName[0..14] -join ""
    #   Password request
    $PasswordEntered = Read-Host -AsSecureString "Input Password"
    $PasswordEnteredNoSecure = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordEntered))
    $password = pass $PasswordEntered $PasswordEnteredNoSecure
    if ($password -contains $PasswordEnteredNoSecure) {
        $YouPass = ""
    }
    else {
        $YouPass = $password
    }
    $PasswordSecureString = $password | ConvertTo-SecureString -AsPlainText -Force
    #   Generation Email
    $Mail = $samAccountName + "@$mail_domain"
    #   Generation UserPrincipalName
    $UserPrincipalName = $samAccountName + "@$dc_domain"
    #   Generation Full Name
    $FullName = $name + " " + $surname
    $usrexist=Get-ADUser -filter {(SamAccountName -eq $samAccountName)} | Select-Object -ExpandProperty SamAccountName
    if ($usrexist -eq $null) {    
        #   Add user on DC
        New-ADUser -Server "$dc_server" -Credential $dc_domain\$Admin -Path "$dc_path" -Name $FullName -GivenName $Name -Surname $Surname -SamAccountName $samAccountName -DisplayName $FullName -EmailAddress $Mail -UserPrincipalName $UserPrincipalName -AccountPassword $PasswordSecureString -Enabled $true
        #   Display the necessary information
        Write-Host "You login: $samAccountName" -ForegroundColor Yellow
        Write-Host "You Email: $Mail" -ForegroundColor Yellow
        Write-Host "You Password: $YouPass" -ForegroundColor Yellow
    }
    else {
        Write-Host "User does exist" -ForegroundColor Red
        $Reset = Read-Host 'Create another user? (y/n)'
        if ($Reset -eq "y") {
            usrcreate
        }
        else {
            if ($Reset -eq "n") {
                Exit
            }
            else {
                Write-Host "Please enter n or y"  
            }
        }
    }
}

#   Domain Admin login
usrcreate $dc_server $dc_path $dc_domain $mail_domain