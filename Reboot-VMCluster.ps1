###################
## Reboot-VMCluster.ps1
## Script reboots each ESXi server in the cluster one at a time
###################

# Set Cluster name and time to sleep
$ClusterName = "Cluster-A"
$timeToSleepDown = 5
$timeToSleepReboot = 120

##################
## Get Server Objects from the cluster
##################
# Get VMware Server Object based on name passed as arg
$MyVMHosts = @(Get-Cluster $ClusterName | Get-VMHost | Sort-Object -Property Name)

##################
## Reboot ESXi Server Function
## Puts an ESXI server in maintenance mode, reboots the server and the puts it back online
## Requires fully automated DRS and enough HA capacity to take a host off line
##################
Function RebootESXiServer ($MyVMHost) {
    # Get Server name
    $ServerName = $MyVMHost.Name

    # Put server in maintenance mode
    Write-Host "#### Rebooting $ServerName ####"
    Write-Host "Entering Maintenance Mode"
    Set-VMhost $MyVMHost -State maintenance -Evacuate | Out-Null

    $ServerState = (Get-VMHost $MyVMHost).ConnectionState
    if ($ServerState -ne "Maintenance") {
        Write-Host "Server did not enter maintanenace mode. Cancelling remaining servers"
        Exit
    }
    Write-Host -NoNewline "ESXi host, $ServerName, is in "
    Write-Host -ForegroundColor Yellow "Maintenance Mode"

    # Reboot blade
    Write-Host "Rebooting..."
    Restart-VMHost $MyVMHost -confirm:$false | Out-Null

    # Wait for Server to show as down
    do {
        Start-Sleep -Seconds $timeToSleepDown
        $ServerState = (Get-VMHost $MyVMHost).ConnectionState
    }
    while ($ServerState -ne "NotResponding")
    Write-Host -NoNewline "ESXi host, $ServerName, is "
    Write-Host -ForegroundColor Red "Down"
    Write-Host "(This is normal for a reboot!)"

    $timeBeforeReboot = Get-Date
    $j = 1
    # Wait for server to reboot
    do {
        Start-Sleep -Seconds $timeToSleepReboot
        $ServerState = (Get-VMHost $MyVMHost).ConnectionState
        Write-Host "...waiting for reboot"
        $j++
    }
    while ($ServerState -ne "Maintenance")
    $timeAfterReboot = Get-Date
    $RebootTime = $(New-TimeSpan -Start $timeBeforeReboot -End $timeAfterReboot).Minutes
    Write-Host "$ServerName is back up. Took $RebootTime minutes"

    # Exit maintenance mode
    Write-Host "Exiting Maintenance mode"
    Set-VMhost $MyVMHost -State Connected | Out-Null
    Write-Host "#### Reboot Complete ####"
    Write-Host ""
}

foreach ($MyVMHost in $MyVMHosts) {
    RebootESXiServer ($MyVMHost)
}