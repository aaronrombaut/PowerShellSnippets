# How to use this file
# Ensure PowerCLI is installed
# Connect to vCenter with:
# $myVCSA = <server-name>
# $myCred = Get-Credential
# Connect-VIServer -Server $myVCSA -Credential $myCred

$myVMHosts = Get-VMHost | Sort-Object -Property Name

$vibName = "dod-esxi70-stig-rd"
$dryrun = "true"    # true | false

# Do not edit below this line...
foreach ($myVMHost in $myVMHosts)
{
    $vmHost = Get-VMHost -Name $myVMHost
    $esxcli = Get-EsxCli -VMHost $myVMHost -V2

    $vmHostVIBs = ($esxcli.software.vib.list.invoke()).Name

    if ($vmHostVIBs.Contains($vibName)) {
        
        $arguments = $esxcli.software.vib.remove.CreateArgs()
        $arguments.dryrun = $dryrun
        $arguments.vibname = $vibName
        
        #$arguments
        $esxcli.software.vib.remove.Invoke($arguments) | Out-Null
            
        Write-host -ForegroundColor Yellow "VIB Removed"
    } else {
        Write-Host -ForegroundColor Red -NoNewline "Warning: "
        Write-Host -NoNewLine "VIB, "
        Write-Host -ForegroundColor Yellow -NoNewLine $vibName
        Write-Host " does not exist!"
    }
}