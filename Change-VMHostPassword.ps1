# How to use this file
# Ensure PowerCLI is installed
# Connect to vCenter with:
# $myVCSA = <server-name>
# $myCred = Get-Credential
# Connect-VIServer -Server $myVCSA -Credential $myCred

$VMHosts = Get-VMHost | Sort-Object
$vmHostUserId = 'sshuser'
$newPassword = 'VMware1!'

# Do not edit below this line...
foreach ($VMHost in $VMHosts)
{
    $esxcli = Get-EsxCli -VMHost $VMHost -V2

    $vmHostUsers = ($esxcli.system.account.list.invoke()).UserId

    if ($vmHostUsers.Contains($vmHostUserId)) {
        #$esxcli.system.account.set.Help()
        $arguments = $esxcli.system.account.set.CreateArgs()
        $arguments.id = $vmHostUserId
        $arguments.password = $newPassword
        $arguments.passwordconfirmation = $newPassword
        #$arguments
        $esxcli.system.account.set.Invoke($arguments) | Out-Null
            
        Write-host -ForegroundColor Yellow "Password changed!"
    } else {
        Write-Host -ForegroundColor Red -NoNewline "Warning: "
        Write-Host -NoNewLine "User ID, "
        Write-Host -ForegroundColor Yellow -NoNewLine $vmHostUserId
        Write-Host " does not exist!"
    }
}

Disconnect-VIServer -Server $myVCSA
