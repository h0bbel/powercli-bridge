## TODO
### What about vSAN? Add check and proper shutdown? https://core.vmware.com/blog/automation-improvements-using-powercli-131-vsan-8-u1
### DRS/HA - Check value before setting DRS partially automated?
### Cycle through VMs again before doing host maintenance mode (wait loop) in case there are still VMs running
### Logic problem: Maintenance mode? Find out where vCenter is, and then wait with that host?
### Numbering in output, is there a better way to do it?
### State: Record HA/DRS/vCLS mode in state as well!

# Timer ref: https://arcanecode.com/2023/05/15/fun-with-powershell-elapsed-timers/
$processTimer = [System.Diagnostics.Stopwatch]::StartNew()
$endpoint = "UPS Shutdown"
$version = "0.1"
Write-Podehost "----------------------------------------------------------------" -ForegroundColor Cyan
Write-Podehost "$endpoint v$version UPS Shutdown event triggered - Running" -ForegroundColor Cyan

# Standard Definitions
$UPSdate = Get-Date -Format "dd/MM/yyyy HH:mm K"
$VMDescription = "$UPSdate : UPS shutdown event detected, shutting down"  

# State: Save the execution time 
Lock-PodeObject -ScriptBlock {
    Set-PodeState -Name 'ExecutionTime' -Value @{ 'Timestamp' = "$UPSdate" } # | Out-Null
    Save-PodeState -Path './states/shutdown_state.json'
}


# Grab config from environment variables defined in .\shared\env.ps1
# Move to dotsource included? for Re-use in other scripts?

$vCenterVMName = $Env:vCenterVMName                 # vCenter VM name - used to exclude the vCenter VM in the shutdown procedure
$vCenterServerFQDN = $Env:vCenterServerFQDN         # vCenter FQDN name, used for the PowerCLI connection
$vCenterUsername = $Env:vCenterUsername             # vCenter username, ex. administrator@vsphere.local
$vCenterPassword = $Env:vCenterPassword             # $vCenterUsername Password

$X_PODE_API_KEY = $Env:X_PODE_API_KEY               # API Key

# Connect to vCenter Server
try {
    Connect-VIServer -Server $vCenterServerFQDN -User $vCenterUsername -Password $vCenterPassword -ErrorAction Stop
    Write-Podehost "1: Connected to vCenter Server <$vCenterServerFQDN> successfully." -Foregroundcolor Green
}
catch {
    Write-Podehost "1: Failed to connect to vCenter Server: <$vCenterServerFQDN> $($_.Exception.Message)" -ForegroundColor Red
    Write-PodeJsonResponse -Value @{ "success" = "false";"message"= "Unable to connect to <$vCenterServerFQDN>";"timestamp"="$DateVar"}
    exit
}

# Get Cluster Data
$cluster = Get-Cluster * 

# Check if vSAN is enabled
# Get-VsanClusterConfiguration | select *
$vsanConfiguration = Get-VsanClusterConfiguration
$vSANEnabled = $vsanConfiguration.VsanEnabled

if ($vSANEnabled -eq 'true')
    {
        Write-Podehost "2: vSAN Enabled" -Foregroundcolor Blue
        # Logic for vSAN shutdown
        # https://core.vmware.com/blog/automation-improvements-using-powercli-131-vsan-8-u1
        # https://developer.broadcom.com/powercli/latest/vmware.vimautomation.storage/commands/stop-vsancluster
        # Is it that easy with vSAN? Just run stop-vsancluster??
    }

else
    {
        Write-Podehost "2: vSAN is not enabled. Continuing without changes. " -Foregroundcolor Green
    }



# Change DRS Automation level to partially automated if required
$DRSLevel = $cluster.DrsAutomationLevel
if ($DRSLevel -eq 'FullyAutomated')
    {
        Write-Podehost "3: DRS Automation Level is <$DRSLevel>. Changing cluster DRS Automation Level to Partially Automated" -Foregroundcolor Blue
        Get-Cluster * | Set-Cluster -DrsAutomation PartiallyAutomated -confirm:$false 
    }

else
    {
        Write-Podehost "3: DRS Automation Level is <$DRSLevel>. Continuing without changes. " -Foregroundcolor Green
    }   

# State: Save the DRS Level
Lock-PodeObject -ScriptBlock {
    Set-PodeState -Name 'DRSLevel' -Value @{ 'DRSLevel' = "$DRSLevel" } # | Out-Null
    Save-PodeState -Path './states/shutdown_state.json'
}


# Change the HA status if required
$HAStatus = $cluster.HAEnabled

if ($HAStatus -eq 'True')
    {
        Write-Podehost "4: HA Status is turned on. Turning off HA on the cluster" -Foregroundcolor Blue
        Get-Cluster * | Set-Cluster -HAEnabled:$false -confirm:$false 
    }

else
    {
        Write-Podehost "4: HA Status is <$HAStatus>. No need to disable HA on the cluster" -Foregroundcolor Green
    }   

# State: Save the HA Status
Lock-PodeObject -ScriptBlock {
    Set-PodeState -Name 'HAStatus' -Value @{ 'HAStatus' = "$HAStatus" } # | Out-Null
    Save-PodeState -Path './states/shutdown_state.json'
}
# vCLS Retreat Mode to ensure proper shutdown
# From https://williamlam.com/2023/09/easily-disable-vsphere-cluster-services-vcls-using-ui-api-in-vsphere-8-0-update-2.html

$clusterName = "cl01" #TODO: Hardcoded for now. Also, needs an if loop to check existing status.
## What about multiple clusters?

(Get-Cluster $clusterName).ExtensionData.ConfigurationEx.SystemVMsConfig.DeploymentMode
$clusterSystemVMSpec = New-Object VMware.Vim.ClusterSystemVMsConfigSpec
$vCLSMode = (Get-Cluster $clusterName).ExtensionData.ConfigurationEx.SystemVMsConfig.DeploymentMode
# ABSENT = vCLS Disabled
# SYSTEM_MANAGED = vCLS Enabled

# State: Save the vCLSMode
Lock-PodeObject -ScriptBlock {
    Set-PodeState -Name 'vCLSMode' -Value @{ 'vCLSMode' = "$vCLSMode" } # | Out-Null
    Save-PodeState -Path './states/shutdown_state.json'
}

if ($vCLSMode -eq 'SYSTEM_MANAGED')
    {
        Write-Podehost "X: vCLS Mode is set to SYSTEM MANAGED, changed to Retreat Mode for proper shutdown/maintenance mode." -Foregroundcolor Blue

        $clusterSystemVMSpec.DeploymentMode = "ABSENT"
        $clusterSpec = New-Object VMware.Vim.ClusterConfigSpecEx
        $clusterSpec.SystemVMsConfig = $clusterSystemVMSpec
        $task = (Get-Cluster $clusterName).ExtensionData.ReconfigureComputeResource_Task($clusterSpec,$true)
        $task1 = Get-Task -Id ("Task-$($task.value)")
        $task1 | Wait-Task
   }


# Graceful shutdown of VMs with VMware Tools, PowerOff on others
# Exclude vCLS VMs & ups-dummy-noshutdown* for testing purposes - ensure those are caught by second stage
$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object  {$_.Name -notlike "vCLS*"} | Where-Object  {$_.Name -notlike $vCenterVMName} | Where-Object  {$_.Name -notlike "ups-dummy-noshutdown*"} # Works! Excludes vCenter!
Write-Podehost "5: Discovered these powered on VMs: <$VMs>" -Foregroundcolor Green 

ForEach ( $VM in $VMs ) 
{
    Write-Podehost "   Processing <$VM>" -ForegroundColor Green
    Write-Podehost "      Checking for VMware Tools" -Foregroundcolor Green
    $VMinfo = get-view -Id $VM.ID
    if ($VMinfo.config.Tools.ToolsVersion -eq 0)
    {
        Write-Podehost "      No VMware tools detected in <$VM>, hard power off" -ForegroundColor Red
        Set-VM $VM -Description "$VMDescription - Hard Shutdown" -confirm:$false
        Stop-VM $VM -confirm:$false
    }
    else
    {
       Write-Podehost "      VMware tools detected, attempting graceful shutdown of <$VM>" -Foregroundcolor Green
       Set-VM $VM -Description "$VMDescription - Graceful Shutdown" -confirm:$false
       Shutdown-VMGuest $VM -Confirm:$false
    }   
}

# Add logic that waits x amount of time after graceful shutdown, rescans and does power off?
# Example in https://github.com/voletri/PowerCLI-1/blob/master/Power-Off-VMs.ps1 line 109
# Once that loop has completed, eg the vm array is empty, shut down $vCenterVMName!

# Second Pass Running VMs
Write-Podehost "5.1: Checking running VMs second pass (waiting)" -Foregroundcolor Green

Start-Sleep -Seconds 45 # Wait a bit before running second pass. TODO: Check if there are still VMs, if not - don't wait?

$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object  {$_.Name -notlike "vCLS*"} | Where-Object  {$_.Name -notlike $vCenterVMName}  # Works! Excludes vCenter!

Write-Podehost "      These VMs are still powered on: <$VMs>" -Foregroundcolor Yellow
ForEach ( $VM in $VMs ) 
{
    Set-VM $VM -Description "$VMDescription - Hard Shutdown" -confirm:$false
    Stop-VM $VM -confirm:$false
    Write-Podehost "      Hard Shutdown of <$VM> performed" -ForegroundColor Red
}

# TODO? Run once more and ensure $VM is empty?

# Maintenance mode

Write-Podehost "6: ESXi Maintenance Mode" -Foregroundcolor Green

$vCVM = Get-VM -name $vCenterVMName # For some reason this makes it double on subsequent runs? Or is it due to vCenter returning double?
$vCHost = $vCVM.VMHost

Write-PodeHost "6.1: Deferring Maintenance Mode for <$vCHost> since vCenter VM <$vCenterVMName> is running on it" -ForegroundColor Green
    # Begin State
    # Store data in a state file, for usage later on for instance in a startup sequence.
    # Does this just add data? Just remove the restore, and add that to the startup sequence seems like the best bet.

Write-Podehost "6.1a: Saving vCenter ESXi host <$vCHost> in state for later use (startup)" -ForegroundColor Red

    # Create the shared variable
    # Need this to empty it out on subsequent runs?
    # Set-PodeState -Name 'vCenterHost' -Value @{ 'values' = @(); } #| Out-Null

    # attempt to re-initialise the previous state (will do nothing if the file doesn't exist)
    # Do not need to restore it here, right?
    # Restore-PodeState -Path './states/shutdown_state.json'
    # Issue: It adds on subsequent runs.

Lock-PodeObject -ScriptBlock {
        #Set-PodeState -Name 'data' -Value @{ 'Name' = 'Rick Sanchez' } | Out-Null
        # Delete previous state, as subsequent runs adds to it and not overwrites, at least for $vCHost for some reason?!
        # We don't really need the previous state here, since we don't use it for anything.
        
    #Remove-PodeState -Name 'vCenterHost'
    #Remove-PodeState -Name 'ExecutionTime'

    Set-PodeState -Name 'vCenterHost' -Value @{ 'vCenterHost' = "$vCHost" } # | Out-Null
    Set-PodeState -Name 'ExecutionTime' -Value @{ 'Timestamp' = "$UPSdate" } # | Out-Null
    Save-PodeState -Path './states/shutdown_state.json'
    }

    $ESXiHosts = Get-VMHost  | Where-Object {$_.name -ne "$vCHost"} #Only loop through non VC hosts
    ForEach ( $ESXiHost in $ESXiHosts )
            {
                Write-Podehost "6.1: Enabling Maintenance Mode on <$ESXiHost>" -ForegroundColor Yellow
                Get-VMHost -Name $ESXiHost | Set-VMHost -State Maintenance
            } 

## The Sleep is required to let MaintenanceMode to kick in - Tweak value? 30 seems OK
## Move to an env variable for customization?
## Is it required?
# Start-Sleep -Seconds 30

# Shut down vCenter goes here.
# Hard shutdown right now (the VM is fake)
# Add logic for check if vCenter is powered on? Kinda weird, as if it isn`t we won`t be able to do anything...

Write-Podehost "6.2: Enable Maintenance Mode on vCenter host" -Foregroundcolor Green
#Get-VMHost -Name $vCHost | Set-VMHost -State Maintenance -RunAsync #Async helps?
#Start-Sleep -Seconds 10

#Write-Podehost "7: Shutting down vCenter VM: <$vCenterVMName>" -Foregroundcolor Green
# Idea to connect directly to the host and shut down the VM & enable maintmode?
# Might be better in a live environment where the vC is within the same cluster/datacenter
# Connect-VIServer -Server IP_ADDRESS -Protocol https -User USER -Password PASS Needs more variables for ESXi host...

#Stop-VM $vCenterVMName -confirm:$false # Should be Shutdown-VMGuest $vCenterVMName -Confirm:$false only Stop because of fake VC.

Write-Podehost "7: Disconnecting from <$vCenterServerFQDN>" -Foregroundcolor Green
Disconnect-VIServer -Server $vCenterServerFQDN -Force -Confirm:$false

# Test with direct host connection instead of vCenter
# TODO: Hardcoded creds

Write-Podehost "8: Connecting to vCenter ESXi host: <$vCHost>" -Foregroundcolor Green

Connect-VIServer -Server $vCHost -user root -password Pronet2012!  # TODO: Remove hardcoding!
Write-Podehost "8.1: Shutting down vCenter VM: <$vCenterVMName>" -Foregroundcolor Green
Stop-VM $vCenterVMName -confirm:$false

Write-Podehost "8.2: Enable Maintenance Mode on vCenter host <$vCHost>" -Foregroundcolor Green
Set-VMHost -State Maintenance
#Disconnect-VIServer -Server $vCHost -Force -Confirm:$false     # This disconnect fails.

# Disconnect all
Disconnect-VIServer -Server * -Force -Confirm:$false

# Completed 

#Timer
$processTimer.Stop()
$ts = $processTimer.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f $ts.Hours, $ts.Minutes, $ts.Seconds, ($ts.Milliseconds / 10)
Write-Podehost "All done - Total Elapsed Time $elapsedTime" -Foregroundcolor Green

#Done
Write-Podehost "Done: All defined UPS shutdown tasks have run, task completed." -ForegroundColor Cyan
Write-Podehost "----------------------------------------------------------------" -ForegroundColor Cyan
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint v$version";"message"= "NUT/UPS initiated shutdown completed in $elapsedTime."}
