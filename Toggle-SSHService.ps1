# How to use this file
# Ensure PowerCLI is installed
# Connect to vCenter with:
# $myVCSA = <server-name>
# $myCred = Get-Credential
# Connect-VIServer -Server $myVCSA -Credential $myCred

param(
    [Parameter()]
    [String]$serviceToggle = 'disabled'   # [enabled | disabled]
)
$myVMHosts = Get-VMHost | Sort-Object

# Do not edit below this line...
foreach ($myVMHost in $myVMHosts)
{
    $sshServiceDetails = Get-VMHostService -Host $myVMHost | Where-Object -Property Key -like 'TSM-SSH'

    # Write-Host "The service is currently " ($sshServiceDetails).Running
    # Write-Host "User wants $serviceToggle"

    if ($sshServiceDetails.Running -and $serviceToggle -like 'enabled') {
        Write-Host -NoNewline "The service is "
        Write-Host -NoNewLine -ForegroundColor Green "running "
        Write-Host "on $myVMHost."
        continue
    } elseif (-not $sshServiceDetails.Running -and $serviceToggle -like 'disabled') {
        Write-Host -NoNewLine "The service is "
        Write-Host -NoNewLine -ForegroundColor Red "stopped "
        Write-Host "on $myVMHost."
        continue
    } 
    
    if ($serviceToggle -like 'enabled') {
        Write-Host "The service is being started!"
        Start-VMHostService -HostService $sshServiceDetails -Confirm:$false
    } elseif ($serviceToggle -like 'disabled') {
        Write-Host "The service is being stopped!"
        Stop-VMHostService -HostService $sshServiceDetails -Confirm:$false
    }

    Write-Host -NoNewline "The SSH service is now "
    $isRunning = (Get-VMHostService -Host $myVMHost | Where-Object -Property Key -like 'TSM-SSH').Running
    if($isRunning) {
        Write-Host -ForegroundColor Green "enabled!"
    } else {
        Write-Host -ForegroundColor Red "disabled!"
    }
}