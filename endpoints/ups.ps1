$endpoint = "UPS Shutdown"
$version = "0.1"
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint version:$version";"message"= "NUT/UPS initiated shutdown started."}
Write-Host "$endpoint version:$version UPS Shutdown event triggered - Running" -ForegroundColor Cyan

# Standard Definitions
$UPSdate = Get-Date -Format "dd/MM/yyyy HH:mm K"
$VMDescription = "$UPSdate : UPS shutdown event detected, shutting down"  


# Dot Source the vSphereEnv.ps1
. $PSScriptRoot\config\vSphereEnv.ps1

#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to vCenter Server
try {
    Connect-VIServer -Server $vCenterServer -User $Username -Password $Password -ErrorAction Stop
    Write-Host "Connected to vCenter Server $vCenterServer successfully." -Foregroundcolor Green
}
catch {
    Write-Host "Failed to connect to vCenter Server: $($_.Exception.Message)" -ForegroundColor Red
    Write-PodeJsonResponse -Value @{ "success" = "false";"message"= "Unable to connect to $vCenterServer";"timestamp"="$DateVar"}
    exit
}

# Proof of Concept Logic
# Temporary test VM
#$TestVM = "ups-dummy-vm01"
#Write-Host "Abusing $TestVM Setting VM description to $VMDescription"
#Set-VM $TestVM -Description $VMDescription -confirm:$false
#Get-VM $TestVM | Shutdown-VMGuest -Confirm:$false # Shut down requires VMware tools
#Get-VM $TestVM | Stop-VM -Confirm:$false


### Actual logic
### Get all powered on VMs (except vCLS) and shut them down!
### What about vCenter? How to ensure it is shut down last? Currently excluded from the logic

## TODO
### What about vSAN? Add check and proper shutdown?
### Maintenance mode?
### DRS?


# Change DRS Automation level to partially automated...
## NOTE: If DRS is not enabled, this sets it... needs a way to check

Write-Host "Changing cluster DRS Automation Level to Partially Automated" -Foregroundcolor Green
Get-Cluster * | Set-Cluster -DrsAutomation PartiallyAutomated -confirm:$false 

# Change the HA Level
Write-Host "Disabling HA on the cluster..." -Foregroundcolor Green
Get-Cluster * | Set-Cluster -HAEnabled:$false -confirm:$false 


# Graceful shutdown of VMs with VMware Tools, PowerOff on others
$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object  {$_.Name -notlike "vCLS*"} | Where-Object  {$_.Name -notlike $vCName} # Works! Excludes vCenter!
Write-Host "Discovered these powered on VMs: $VMs" -Foregroundcolor Green 

ForEach ( $VM in $VMs ) 
{
    Write-Host "Processing $VM ...." -ForegroundColor Green
    Write-Host "Checking for VMware tools install" -Foregroundcolor Green
    $VMinfo = get-view -Id $VM.ID
    if ($VMinfo.config.Tools.ToolsVersion -eq 0)
    {
        Write-Host "No VMware tools detected in $VM, hard power off" -ForegroundColor Red
        Set-VM $VM -Description "$VMDescription - Hard Shutdown" -confirm:$false
        Stop-VM $VM -confirm:$false
    }
    else
    {
       Write-Host "VMware tools detected, attempting graceful shutdown of $VM" -Foregroundcolor Green
       Set-VM $VM -Description "$VMDescription - Graceful Shutdown" -confirm:$false
       Shutdown-VMGuest $VM -Confirm:$false
    }   
}

# Add logic that waits x amount of time after graceful shutdown, rescans and does power off?
# Example in https://github.com/voletri/PowerCLI-1/blob/master/Power-Off-VMs.ps1 line 109
# Once that loop has completed, eg the vm array is empty, shut down vCname!

# Maintenance mode
# Get all hosts
#Write-Host "Found ESXi Hosts:" $ESXiHost


## Start-Job to make script continue while waiting for maintenance mode to continue
## Start-Job needs its own connection to vCenter, ref https://www.lucd.info/knowledge-base/running-a-background-job/

Write-Host "Entering Maintenance mode ..." -Foregroundcolor Green

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
        Get-VMHost -Name $ESXiHost | Set-VMHost -State Maintenance
    }
    }

    $MaintenanceModeJob = @{
    ScriptBlock = $MaintenanceMode
    ArgumentList = $global:DefaultVIServer.Name, $global:DefaultVIServer.SessionId
    }
    Start-Job @MaintenanceModeJob



## The Sleep is required for MaintenanceMode to kick in - Tweak value? 30 seems OK
Start-Sleep -Seconds 30

# Shut down vCenter goes here.
# Hard shutdown right now (the VM is fake)
# Logic problem: Maintenance mode wont trigger on the host the VC is on, since the VC is still running.
# Logic problem 2: Removed -Description "$VMDescription - Hard Shutdown" since you cant edit a VM when maintenance mode is trying to enable! Not possible to do this at this stage, if description is needed it needs to be done earlier.
Write-Host "Shutting down $vCenterServer  ..." -Foregroundcolor Green

# Set-VM $vCName -Description "$VMDescription - Hard Shutdown" -confirm:$false
Stop-VM $vCName -confirm:$false

# Completed 
## Remove disconnect? Not needed when vCenter is actually shut down prior
Write-Host "Disconnecting from $vCenterServer" -Foregroundcolor Green
Disconnect-VIServer -Server $vCenterServer -Force -Confirm:$false
Write-Host "All defined UPS shutdown tasks have run, task completed." -ForegroundColor Cyan
