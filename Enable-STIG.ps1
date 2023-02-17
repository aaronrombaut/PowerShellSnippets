#######################
# Variables           #
#######################
$LockdownLevel = "lockdownNormal"
$VMHosts = Get-VMHost | Sort-Object -Property Name
$VirtualMachines = Get-VM | Sort-Object -Property Name  | Where-Object -NotLike -Property Name "vCLS*"
$DCUIAccessUser = "root"
$LockdownExceptionUsers = "esximgmt", "root", "vxpsvc_ptagent_op"
$SyslogLogHost = "udp://vrli.aaronrombaut.com:514"
$WelcomeMessage = "You are not welcome here!"
$ConfigEtcIssue = "This is an /etc/issue message"
$EsxAdminsGroup = "vCenter Admins"
$SyslogGlobalDir = ""
$VCSAName = "vcsa.aaronrombaut.com"

#######################
# Functions           #
#######################
function Set-VMHostAdvancedSetting {
    param (
        $VMhost,
        $AdvancedSettingName,
        $AdvancedSettingValue
    )

    Get-VMHost -Name $VMHost | Get-AdvancedSetting -Name $AdvancedSettingName | Set-AdvancedSetting -Value $AdvancedSettingValue -Confirm:$false
}

function Set-VCSAAdvancedSetting {
    param (
        $VCSAEntity,
        $AdvancedSettingName,
        $AdvancedSettingValue
    )

    # Test if the Advanced Setting exists already
    if (Get-AdvancedSetting -Entity $VCSAEntity -Name $AdvancedSettingName) {
        Get-AdvancedSetting -Entity $VCSAEntity -Name $AdvancedSettingName | Set-AdvancedSetting -Value $AdvancedSettingValue -Confirm:$false
    } else {
        New-AdvancedSetting -Entity $VCSAEntity -Name $AdvancedSettingName -Value $AdvancedSettingValue -Confirm:$false
    }
}

function Set-VMAdvancedSetting {
    param (
        $VMname,
        $AdvancedSettingName,
        $AdvancedSettingValue
    )
    
    # Test if the Advanced Setting exists already
    if (Get-VM -Name $VMname | Get-AdvancedSetting -Name $AdvancedSettingName) {
        Get-VM -Name $VMname | Get-AdvancedSetting -Name $AdvancedSettingName | Set-AdvancedSetting -Value $AdvancedSettingValue -Confirm:$false
    } else {
        Get-VM -Name $VMname | New-AdvancedSetting -Name $AdvancedSettingName -Value $AdvancedSettingValue -Confirm:$false
    }
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

#######################
# ESXi STIG Items     #
#######################
foreach ($VMHost in $VMHosts) {
    
    Write-Host -NoNewline "Starting to STIG "
    Write-Host -ForegroundColor Yellow -NoNewline "$VMHost"
    Write-Host ""
    
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
        #Add-LockdownExceptionUser -VMHost $VMHost -LockdownExceptionUser $LockdownExceptionUsers
    }

    ## STIG ID: ESXI-70-000004
    # Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Syslog.global.logHost" -AdvancedSettingValue $SyslogLogHost

    ## STIG ID: ESXI-70-000005
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Security.AccountLockFailures" -AdvancedSettingValue "3"

    ## STIG ID: ESXI-70-000006
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Security.AccountUnlockTime" -AdvancedSettingValue "900"

    ## STIG ID: ESXI-70-000007
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Annotations.WelcomeMessage" -AdvancedSettingValue $WelcomeMessage

    ## STIG ID: ESXI-70-000008
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Config.Etc.issue" -AdvancedSettingValue $ConfigEtcIssue

    ## STIG ID: ESXI-70-000030
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Config.HostAgent.log.level" -AdvancedSettingValue "info"

    ## STIG ID: ESXI-70-000031
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Security.PasswordQualityControl" -AdvancedSettingValue "similar=deny retry=3 min=disabled,disabled,disabled,disabled,15"

    ## STIG ID: ESXI-70-000032
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Security.PasswordHistory" -AdvancedSettingValue "5"

    ## STIG ID: ESXI-70-000034
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Config.HostAgent.plugins.solo.enableMob" -AdvancedSettingValue "false"

    ## STIG ID: ESXI-70-000039
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Config.HostAgent.plugins.hostsvc.esxAdminsGroup" -AdvancedSettingValue $EsxAdminsGroup

    ## STIG ID: ESXI-70-000041
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "UserVars.ESXiShellInteractiveTimeOut" -AdvancedSettingValue "120"

    ## STIG ID: ESXI-70-000042
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "UserVars.ESXiShellTimeOut" -AdvancedSettingValue "600"

    ## STIG ID: ESXI-70-000043
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "UserVars.DcuiTimeOut" -AdvancedSettingValue "120"

    ## STIG ID: ESXI-70-000045
    # Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Syslog.global.logDir" -AdvancedSettingValue $SyslogGlobalDir

    ## STIG ID: ESXI-70-000055
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Mem.ShareForceSalting" -AdvancedSettingValue "2"

    ## STIG ID: ESXI-70-000058
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Net.BlockGuestBPDU" -AdvancedSettingValue "1"

    ## STIG ID: ESXI-70-000062
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Net.DVFilterBindIpAddress" -AdvancedSettingValue ""

    ## STIG ID: ESXI-70-000074
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "UserVars.ESXiVPsDisabledProtocols" -AdvancedSettingValue "tlsv1,tlsv1.1,sslv3"
    Write-Host -ForegroundColor Red -NoNewline "Warning"
    Write-Host ": ESXi host requires reboot!"

    ## STIG ID: ESXI-70-000079
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "UserVars.SuppressShellWarning" -AdvancedSettingValue "0"

    ## STIG ID: ESXI-70-000081
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "UserVars.SuppressHyperthreadWarning" -AdvancedSettingValue "0"

    ## STIG ID: ESXI-70-000087
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Mem.MemEagerZero" -AdvancedSettingValue "1"

    ## STIG ID: ESXI-70-000088
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Config.HostAgent.vmacore.soap.sessionTimeout" -AdvancedSettingValue "30"

    ## STIG ID: ESXI-70-000089
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "UserVars.HostClientSessionTimeout" -AdvancedSettingValue "600"

    ## STIG ID: ESXI-70-000091
    Set-VMHostAdvancedSetting -VMhost $VMHost -AdvancedSettingName "Security.PasswordMaxDays" -AdvancedSettingValue "90"

    Write-Host ""
    Write-Host ""
}


#######################
# vCenter Items       #
#######################

## STIG ID: VCSA-70-000034
Set-VCSAAdvancedSetting -VCSAEntity $VCSAName -AdvancedSettingName "config.log.level" -AdvancedSettingValue "info"

## STIG ID: VCSA-70-000275
Set-VCSAAdvancedSetting -VCSAEntity $VCSAName -AdvancedSettingName " VirtualCenter.VimPasswordExpirationInDays" -AdvancedSettingValue "30"

## STIG ID: VCSA-70-000276
Set-VCSAAdvancedSetting -VCSAEntity $VCSAName -AdvancedSettingName "config.vpxd.hostPasswordLength" -AdvancedSettingValue "32"

## STIG ID: VCSA-70-000280
Set-VCSAAdvancedSetting -VCSAEntity $VCSAName -AdvancedSettingName "vpxd.event.syslog.enabled" -AdvancedSettingValue "true"

foreach ($VirtualMachine in $VirtualMachines) {

    Write-Host -NoNewline "Starting to STIG "
    Write-Host -ForegroundColor Yellow -NoNewline "$VirtualMachine"
    Write-Host ""

    #######################
    # Virtual Machines    #
    #######################

    ## STIG ID: VMCH-70-000001
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "isolation.tools.copy.disable" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000002
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "isolation.tools.dnd.disable" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000003
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "isolation.tools.paste.disable" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000004
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "isolation.tools.diskShrink.disable" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000005
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "isolation.tools.diskWiper.disable" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000007
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "isolation.tools.hgfsServerSet.disable" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000013
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "RemoteDisplay.maxConnections" -AdvancedSettingValue "1"

    ## STIG ID: VMCH-70-000015
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "tools.setinfo.sizeLimit" -AdvancedSettingValue "1048576"

    ## STIG ID: VMCH-70-000016
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "isolation.device.connectable.disable" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000017
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "tools.guestlib.enableHostInfo" -AdvancedSettingValue "false"

    ## STIG ID: VMCH-70-000022
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "tools.guest.desktop.autolock" -AdvancedSettingValue "true"

    ## STIG ID: VMCH-70-000023
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "mks.enable3d" -AdvancedSettingValue "false"

    ## STIG ID: VMCH-70-000026
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "log.rotateSize" -AdvancedSettingValue "2048000"

    ## STIG ID: VMCH-70-000027
    Set-VMAdvancedSetting -VMname $VirtualMachine -AdvancedSettingName "log.keepOld" -AdvancedSettingValue "10"

    Write-Host ""
    Write-Host ""
}