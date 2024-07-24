$endpoint = "UPS"
$version = "0.1"
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint version:$version";"message"= "NUT/UPS initiated shutdown started."}
Write-Host "UPS triggered - Running"

# Standard Definitions
$UPSdate = Get-Date -Format "dd/MM/yyyy HH:mm K"
$VMDescription = "$UPSdate : UPS event detected, shutting down"  

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
    Write-Host "Connected to vCenter Server successfully."
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
#$VMs = Get-VM | Where-Object {$_.powerstate -eq ‘PoweredOn’} | Where-Object -Property Name -NotLike "vCLS*" | Shutdown-VMGuest -Confirm:$false

# NOTE: This does POWER OFF, not graceful SHUTDOWN.
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
Write-Host "All defined tasks have run, task completed."
