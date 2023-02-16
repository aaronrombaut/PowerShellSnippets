## Variables ##
$LockdownLevel = "lockdownNormal"
$VMHosts = Get-VMHost | Sort-Object -Property Name
$DCUIAccessUser = "root"
$LockdownExceptionUsers = "esximgmt", "root", "vxpsvc_ptagent_op"


function Set-VMHostAdvancedSetting {
    param (
        $VMhost,
        $AdvancedSettingName,
        $AdvancedSettingValue
    )

    Get-VMHost -Name $VMHost | Get-AdvancedSetting -Name $AdvancedSettingName | Set-AdvancedSetting -Value $AdvancedSettingValue
}

function Add-LockdownExceptionUser {
    param (
        $VMHost,
        $LockdownExceptionUser
    )
    $VMHostView = Get-VMHost -Name $VMHost | Get-View
    $Lockdown = Get-View -Id $VMHostView.ConfigManager.HostAccessManager
    $Lockdown.UpdateLockdownExceptions($LockdownExceptionUser)
}

function Get-LockdownExceptionUsers {
    param (
        $VMHost
    )

    $VMHostView = Get-VMHost -Name $VMHost | Get-View
    $Lockdown = Get-View -Id $VMHostView.ConfigManager.HostAccessManager
    $Lockdown.QueryLockdownExceptions()

}
function Update-LockdownMode {
    param (
        $VMHost,
        $LockdownLevel
    )

    $VMHostView = Get-VMHost -Name $VMHost | Get-View
    $Lockdown = Get-View -Id $VMHostView.ConfigManager.HostAccessManager
    $Lockdown.ChangeLockdownMode($LockdownLevel)
}

foreach ($VMHost in $VMHosts) {
    ## STIG ID: ESXI-70-000001
    Update-LockdownMode -VMHost $VMHost -LockdownLevel $LockdownLevel

    ## STIG ID: ESXI-70-000002
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "DCUI.Access" -AdvancedSettingValue $DCUIAccessUser

    ## STIG ID: ESXI-70-000003
    $CurrentLockdownExceptionUsers = Get-LockdownExceptionUsers -VMHost $VMHost
    if ($CurrentLockdownExceptionUsers) {
        ## There are Exception Users
        foreach ($CurrentLockdownExceptionUser in $CurrentLockdownExceptionUsers) {
            if (-not ($LockdownExceptionUsers).Contains($CurrentLockdownExceptionUser)) {
                Add-LockdownExceptionUser -VMHost $VMHost -LockdownExceptionUser $CurrentLockdownExceptionUser
            }
        } 
    }
    else {
        ## There are no Exception Users
        Write-Host "Here"
        Add-LockdownExceptionUser -VMHost $VMHost -LockdownExceptionUser $LockdownExceptionUsers
    }
}
