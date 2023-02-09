# How to use this file
# Ensure PowerCLI is installed
# Connect to vCenter with:
# $myVCSA = <server-name>
# $myCred = Get-Credential
# Connect-VIServer -Server $myVCSA -Credential $myCred

$myVMHosts = Get-VMHost | Sort-Object -Property Name

$serviceKeys = "TSM-SSH" # Comma-separated list

## Do not edit below this line...
foreach ($myVMHost in $myVMHosts)
{
    Write-Host -NoNewline -ForegroundColor Yellow "Host: "
    Write-Host $myVMHost
    
    # $esxcli = Get-EsxCli -VMHost $myVMHost -V2
 
    ## PostConditioner to be STIG compliant again.
    foreach ($serviceKey in $serviceKeys) {
        Get-VMHost -Name $myVMHost | Get-VMHostService | Where-Object {$_.Key -eq $serviceKey} | Set-VMHostService -Policy Off
        Get-VMHost -Name $myVMHost | Get-VMHostService | Where-Object {$_.Key -eq $serviceKey} | Stop-VMHostService
    }

    Write-Output ""
    Write-Output ""
}