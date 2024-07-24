$endpoint = "UPS Shutdown"
$version = "0.1"
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint version:$version";"message"= "NUT/UPS initiated shutdown started."}
Write-Host "$endpoint version:$version UPS Shutdown event triggered - Running"

# Standard Definitions
$UPSdate = Get-Date -Format "dd/MM/yyyy HH:mm K"
$VMDescription = "$UPSdate : UPS shutdown event detected, shutting down"  

# Define vCenter Server details
# Could this be included from external source?

$vCenterServer = "vc01.explabs.badunicorn.no"
$Username = "administrator@vsphere.local"
$Password = "Pronet2012!"

#Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to vCenter Server
try {
    Connect-VIServer -Server $vCenterServer -User $Username -Password $Password -ErrorAction Stop
    Write-Host "Connected to vCenter Server $vCenterServer successfully."
}
catch {
    Write-Host "Failed to connect to vCenter Server: $($_.Exception.Message)" -ForegroundColor Red
    Write-PodeJsonResponse -Value @{ "success" = "false";"message"= "Unable to connect to $vCenterServer";"timestamp"="$DateVar"}
    exit
}

# Proof of Concept Logic
# Temporary test VM
# Currently sets VM description to a timestamp, and forcefully shuts it down.
# Needs logic to loop through all VMs and shut them down gracefully.

#$TestVM = "ups-dummy-vm01"
#Write-Host "Abusing $TestVM Setting VM description to $VMDescription"
#Set-VM $TestVM -Description $VMDescription -confirm:$false
#Get-VM $TestVM | Shutdown-VMGuest -Confirm:$false # Shut down requires VMware tools
#Get-VM $TestVM | Stop-VM -Confirm:$false


### Actual logic
### Get all powered on VMs (except vCLS) and shut them down!
### What about vCenter? How to ensure it is shut down last?
###     Use tags for this? Exclude a tag until no VMs are powered on, and then power off the vc vm?
#$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object -Property Name -NotLike "vCLS*" | Shutdown-VMGuest -Confirm:$false

# NOTE: This does POWER OFF, not graceful SHUTDOWN
# https://github.com/voletri/PowerCLI-1/blob/master/Power-Off-VMs.ps1 has logic for checking VMware Tools status in VM (line 99)
#       This also overwrites the notes field it does not retain existing notes if any.
#       Would it be better to create a logfile instead?

$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object -Property Name -NotLike "vCLS*" | Set-VM -Description $VMDescription -confirm:$false | Stop-VM -Confirm:$false
Write-Host "Discovered these powered on VMs: $VMs - Shutting down"




# Add logic that waits x amount of time after graceful shutdown, rescans and does power off?
# Shutdown-VMGuest/Stop-VM doesn't work without VMware tools


# Get all hosts
#$ESXiHost = Get-VMHost
#Write-Host "Found ESXi Hosts:" $ESXiHost

# Completed
Write-Host "Disconnecting from $vCenterServer"
Disconnect-VIServer -Server $vCenterServer -Force -Confirm:$false
Write-Host "All defined UPS shutdown tasks have run, task completed."
