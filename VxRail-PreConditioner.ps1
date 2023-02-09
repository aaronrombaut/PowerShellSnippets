# How to use this file
# Ensure PowerCLI is installed
# Connect to vCenter with:
# $myVCSA = <server-name>
# $myCred = Get-Credential
# Connect-VIServer -Server $myVCSA -Credential $myCred

$myVMHosts = Get-VMHost | Sort-Object -Property Name

$vibName = "dod-esxi70-stig-rd"
$serviceKeys = "TSM-SSH", "sfcbd-watchdog" # comma-separated list

## Do not edit below this line...
foreach ($myVMHost in $myVMHosts)
{
    Write-Host -NoNewline -ForegroundColor Yellow "Host: "
    Write-Host $myVMHost

    $esxcli = Get-EsxCli -VMHost $myVMHost -V2

    ## Check for the vib
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
        Write-Host -NoNewLine "The VIB, "
        Write-Host -ForegroundColor Yellow -NoNewLine $vibName
        Write-Host ", does not exist!"
    }

    ## Check the services -- this will invalidate STIG
    ##   but is necessary for a smooth upgrade. Run a 
    ##   PostConditioner to be STIG compliant again.
    foreach ($serviceKey in $serviceKeys) {
        Get-VMHost -Name $myVMHost | Get-VMHostService | Where-Object {$_.Key -eq $serviceKey} | Set-VMHostService -Policy On
        Get-VMHost -Name $myVMHost | Get-VMHostService | Where-Object {$_.Key -eq $serviceKey} | Start-VMHostService
    }

    Write-Output ""
    Write-Output ""
}