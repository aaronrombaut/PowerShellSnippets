###################
## reboot-vmcluster.ps1 
## Supply the hostname/FQDN for you vcenter server and the name of the cluster you want rebooted
## Script reboots each ESXi server in the cluster one at a time
###################
##################
## Args
##################
# Check to make sure an argument was passed
if ($args.count -ne 2) {
Write-Host “Usage: reboot-vmcluster.ps1 ”
exit
}

# Set vCenter and Cluster name from Arg
$vCenterServer = $args[0]
$ClusterName = $args[1]

##################
## Connect to infrastructure
##################
Connect-VIServer -Server $vCenterServer | Out-Null

##################
## Get Server Objects from the cluster
##################
# Get VMware Server Object based on name passed as arg
$ESXiServers = @(get-cluster $ClusterName | get-vmhost)

##################
## Reboot ESXi Server Function
## Puts an ESXI server in maintenance mode, reboots the server and the puts it back online
## Requires fully automated DRS and enough HA capacity to take a host off line
##################
Function RebootESXiServer ($CurrentServer) {
# Get Server name
$ServerName = $CurrentServer.Name

# Put server in maintenance mode
Write-Host “#### Rebooting $ServerName ####”
Write-Host “Entering Maintenance Mode”
Set-VMhost $CurrentServer -State maintenance -Evacuate | Out-Null

$ServerState = (get-vmhost $ServerName).ConnectionState
if ($ServerState -ne “Maintenance”)
{
Write-Host “Server did not enter maintanenace mode. Cancelling remaining servers”
Disconnect-VIServer -Server $vCenterServer -Confirm:$False
Exit
}
Write-Host “$ServerName is in Maintenance Mode”

# Reboot blade
Write-Host “Rebooting”
Restart-VMHost $CurrentServer -confirm:$false | Out-Null

# Wait for Server to show as down
do {
sleep 15
$ServerState = (get-vmhost $ServerName).ConnectionState
}
while ($ServerState -ne “NotResponding”)
Write-Host “$ServerName is Down”

$j=1
# Wait for server to reboot
do {
sleep 120
$ServerState = (get-vmhost $ServerName).ConnectionState
Write-Host “… Waiting for reboot”
$j++
}
while ($ServerState -ne “Maintenance”)
$RebootTime=$j/2
Write-Host “$ServerName is back up. Took $RebootTime minutes”

# Exit maintenance mode
Write-Host “Exiting Maintenance mode”
Set-VMhost $CurrentServer -State Connected | Out-Null
Write-Host “#### Reboot Complete####”
Write-Host “”
}

##################
## MAIN
##################
foreach ($ESXiServer in $ESXiServers) {
RebootESXiServer ($ESXiServer)
}

##################
## Cleanup
##################
# Close vCenter connection
Disconnect-VIServer -Server $vCenterServer -Confirm:$False
