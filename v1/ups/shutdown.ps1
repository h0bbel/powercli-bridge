## TODO
### What about vSAN? Add check and proper shutdown? https://core.vmware.com/blog/automation-improvements-using-powercli-131-vsan-8-u1
### DRS/HA - Check value before setting DRS partially automated?
### Cycle through VMs again before doing host maintenance mode (wait loop) in case there are still VMs running
### Logic problem: Maintenance mode? Find out where vCenter is, and then wait with that host?
### Numbering in output, is there a better way to do it?

# Timer ref: https://arcanecode.com/2023/05/15/fun-with-powershell-elapsed-timers/
$processTimer = [System.Diagnostics.Stopwatch]::StartNew()
$endpoint = "UPS Shutdown"
$version = "0.1"
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "$endpoint v$version UPS Shutdown event triggered - Running" -ForegroundColor Cyan

# Standard Definitions
$UPSdate = Get-Date -Format "dd/MM/yyyy HH:mm K"
$VMDescription = "$UPSdate : UPS shutdown event detected, shutting down"  

# Grab config from environment variables defined in .\shared\env.ps1
#Write-Host "Environment" -ForegroundColor Cyan
#. .\shared\env.ps1
#. "$PSScriptRoot\shared\env.ps1"
#Write-Host "vCenterUsername from env.ps1: $vCenterUsername"

$vCenterVMName = $Env:vCenterVMName                 # vCenter VM name - used to exclude the vCenter VM in the shutdown procedure
$vCenterServerFQDN = $Env:vCenterServerFQDN         # vCenter FQDN name, used for the PowerCLI connection
$vCenterUsername = $Env:vCenterUsername             # vCenter username, ex. administrator@vsphere.local
$vCenterPassword = $Env:vCenterPassword             # $vCenterUsername Password

$X_PODE_API_KEY = $Env:X_PODE_API_KEY               # API Key

# Connect to vCenter Server
try {
    Connect-VIServer -Server $vCenterServerFQDN -User $vCenterUsername -Password $vCenterPassword -ErrorAction Stop
    Write-Host "1: Connected to vCenter Server <$vCenterServerFQDN> successfully." -Foregroundcolor Green
}
catch {
    Write-Host "1: Failed to connect to vCenter Server: <$vCenterServerFQDN> $($_.Exception.Message)" -ForegroundColor Red
    Write-PodeJsonResponse -Value @{ "success" = "false";"message"= "Unable to connect to <$vCenterServerFQDN>";"timestamp"="$DateVar"}
    exit
}

# Change DRS Automation level to partially automated if required

$cluster = Get-Cluster * # debugging! We are getting somewhere. $drslevel.DrsAutomationLevel contains status
$DRSLevel = $cluster.DrsAutomationLevel
if ($DRSLevel -eq 'FullyAutomated')
    {
        Write-Host "2: DRS Automation Level is <$DRSLevel>. Changing cluster DRS Automation Level to Partially Automated" -Foregroundcolor Green
        Get-Cluster * | Set-Cluster -DrsAutomation PartiallyAutomated -confirm:$false 
    }

else
    {
        Write-Host "2: DRS Automation Level is <$DRSLevel>. Continuing without changes. " -Foregroundcolor Green
    }   

# Change the HA status if required

$HAStatus = $cluster.HAEnabled

if ($HAStatus -eq 'True')
    {
        Write-Host "3: HA Status is <$HAStatus>. Disabling HA on the cluster" -Foregroundcolor Green
        Get-Cluster * | Set-Cluster -HAEnabled:$false -confirm:$false 
    }

else
    {
        Write-Host "3: HA Status is <$HAStatus>. No need to disable HA on the cluster" -Foregroundcolor Green
    }   


# Graceful shutdown of VMs with VMware Tools, PowerOff on others
# Exclude vCLS VMs & ups-dummy-noshutdown* for testing purposes - ensure those are caught by second stage

$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object  {$_.Name -notlike "vCLS*"} | Where-Object  {$_.Name -notlike $vCenterVMName} | Where-Object  {$_.Name -notlike "ups-dummy-noshutdown*"} # Works! Excludes vCenter!
Write-Host "4: Discovered these powered on VMs: <$VMs>" -Foregroundcolor Green 

ForEach ( $VM in $VMs ) 
{
    Write-Host "   Processing <$VM>" -ForegroundColor Green
    Write-Host "      Checking for VMware Tools" -Foregroundcolor Green
    $VMinfo = get-view -Id $VM.ID
    if ($VMinfo.config.Tools.ToolsVersion -eq 0)
    {
        Write-Host "      No VMware tools detected in <$VM>, hard power off" -ForegroundColor Red
        Set-VM $VM -Description "$VMDescription - Hard Shutdown" -confirm:$false
        Stop-VM $VM -confirm:$false
    }
    else
    {
       Write-Host "      VMware tools detected, attempting graceful shutdown of <$VM>" -Foregroundcolor Green
       Set-VM $VM -Description "$VMDescription - Graceful Shutdown" -confirm:$false
       Shutdown-VMGuest $VM -Confirm:$false
    }   
}

# Add logic that waits x amount of time after graceful shutdown, rescans and does power off?
# Example in https://github.com/voletri/PowerCLI-1/blob/master/Power-Off-VMs.ps1 line 109
# Once that loop has completed, eg the vm array is empty, shut down $vCenterVMName!

# Second Pass Running VMs
Write-Host "4.5: Checking running VMs second pass (waiting)" -Foregroundcolor Green

Start-Sleep -Seconds 45 # Wait a bit before running second pass. TODO: Check if there are still VMs, if not - don't wait?

$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object  {$_.Name -notlike "vCLS*"} | Where-Object  {$_.Name -notlike $vCenterVMName}  # Works! Excludes vCenter!

Write-Host "      These VMs are still powered on: <$VMs>" -Foregroundcolor Yellow
ForEach ( $VM in $VMs ) 
{
    Set-VM $VM -Description "$VMDescription - Hard Shutdown" -confirm:$false
    Stop-VM $VM -confirm:$false
    Write-Host "      Hard Shutdown of <$VM> performed" -ForegroundColor Red
}

# TODO? Run once more and ensure $VM is empty?

# Maintenance mode
## Start-Job to make script continue while waiting for maintenance mode to continue
## Start-Job needs its own connection to vCenter, ref https://www.lucd.info/knowledge-base/running-a-background-job/

Write-Host "5: ESXi Maintenance Mode" -Foregroundcolor Green

$MaintenanceMode = {
    param(
    [string]$Server,
    [string]$SessionId
    )
    Set-PowerCLIConfiguration -DisplayDeprecationWarnings $false -Confirm:$false | Out-Null
    Connect-VIServer -Server $Server -Session $SessionId
    $ESXiHosts = Get-VMHost
    ForEach ( $ESXiHost in $ESXiHosts )
        {
            Write-Host "   Enabling Maintenance Mode on <$ESXiHost>" -ForegroundColor Green # Does not get printed anywhere.
            Get-VMHost -Name $ESXiHost | Set-VMHost -State Maintenance
            
        }
    }

    $MaintenanceModeJob = @{
    ScriptBlock = $MaintenanceMode
    ArgumentList = $global:DefaultVIServer.Name, $global:DefaultVIServer.SessionId
    }
    Start-Job @MaintenanceModeJob

## The Sleep is required to let MaintenanceMode to kick in - Tweak value? 30 seems OK
Start-Sleep -Seconds 30

# Shut down vCenter goes here.
# Hard shutdown right now (the VM is fake)
# Logic problem: Maintenance mode wont trigger on the host the VC is on, since the VC is still running.
# Logic problem 2: Removed -Description "$VMDescription - Hard Shutdown" since you cant edit a VM when maintenance mode is trying to enable! Not possible to do this at this stage, if description is needed it needs to be done earlier.

Write-Host "6: Shutting down <$vCenterVMName>" -Foregroundcolor Green
Stop-VM $vCenterVMName -confirm:$false

# Completed 
## Remove disconnect? Not needed when vCenter is actually shut down prior
Write-Host "7: Disconnecting from <$vCenterServerFQDN>" -Foregroundcolor Green
Disconnect-VIServer -Server $vCenterServerFQDN -Force -Confirm:$false

#Timer
$processTimer.Stop()
$ts = $processTimer.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f $ts.Hours, $ts.Minutes, $ts.Seconds, ($ts.Milliseconds / 10)
Write-Host "All done - Total Elapsed Time $elapsedTime" -Foregroundcolor Green

Write-Host "Done: All defined UPS shutdown tasks have run, task completed." -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint v$version";"message"= "NUT/UPS initiated shutdown completed in $elapsedTime."}
