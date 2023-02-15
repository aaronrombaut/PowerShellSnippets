###################
## Reboot-VMCluster.ps1
## Script checks for vSAN enabled cluster and reboots each ESXi host
## in the cluster one at a time accordingly
###################

# Set variables
$ClusterName = "Cluster-A"
$TimeToSleepDown = 5    # How long to wait before showing ESXi host as down
$TimeToSleepReboot = 120    # How long to wait before checking ESXi host connection status
$VsanEnabled = (Get-VsanClusterConfiguration -Cluster $ClusterName).VsanEnabled
$VsanDataMigrationMode = "EnsureAccessibility" # EnsureAccessibility | Full | NoDataMigration

##################
## Get ESXi host Objects from the cluster
##################
$MyVMHosts = @(Get-Cluster $ClusterName | Get-VMHost | Sort-Object -Property Name)

##################
## Reboot ESXi host Function
## Puts an ESXI host in Maintenance Mode, reboots the server and then puts it back online
## Requires fully automated DRS and enough HA capacity to take a host off-line
##################
Function RebootESXiHost($MyVMHost) {
    # Get Server name
    $ServerName = $MyVMHost.Name

    # Put server in maintenance mode
    Write-Host "#### Rebooting $ServerName ####"
    Write-Host "Entering Maintenance Mode"
    if ($VsanEnabled) {
        Write-Host "ESXi host is vSAN Enabled"
        Set-VMhost -VMHost $MyVMHost -State Maintenance -Evacuate -VsanDataMigrationMode $VsanDataMigrationMode | Out-Null
    } else {
        Write-Host "ESXi host is not vSAN Enabled"
        Set-VMhost -VMHost $MyVMHost -State Maintenance -Evacuate | Out-Null
    }

    $ServerState = (Get-VMHost $MyVMHost).ConnectionState
    if ($ServerState -ne "Maintenance") {
        Write-Host "ESXi host did not enter Maintenance Mode. Canceling remaining servers..."
        Exit
    }
    Write-Host -NoNewline "ESXi host, $ServerName, is in "
    Write-Host -ForegroundColor Yellow "Maintenance Mode"

    # Reboot blade
    Write-Host "Rebooting..."
    Restart-VMHost $MyVMHost -confirm:$false | Out-Null

    # Wait for ESXi host to show as down
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
    Write-Host "Exiting Maintenance Mode"
    Set-VMhost $MyVMHost -State Connected | Out-Null
    Write-Host "#### Reboot Complete ####"
    Write-Host ""
}

foreach ($MyVMHost in $MyVMHosts) {
    RebootESXiHost ($MyVMHost)
}