$endpoint = "UPS"
$version = "0.1"
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint version:$version";"message"= "This is where the UPS logic goes"}
Write-Host "UPS triggered - Running"

# Standard Definitions
$DateVar = Get-Date -Format "dd/MM/yyyy HH:mm K"
$endpoint = "vmtools/vsphere"
$version = "0.1"

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

# Temporary test VM
# Currently sets VM description to a timestamp, and forcefully shuts it down.
# Needs logic to loop through all VMs and shut them down gracefully.

$TestVM = "ups-dummy-vm01"
Write-Host "Abusing " $TestVM
Write-Host "Setting VM description to" $DateVar "on" $TestVM
Set-VM $TestVM -Description $DateVar -confirm:$false
# Get-VM $TestVM | Shutdown-VMGuest -Confirm:$false # Shut down requires VMware tools
Get-VM $TestVM | Stop-VM -Confirm:$false

# Shutdown-VMGuest/Stop-VM doesn't work without VMware tools
# Add in power-off for VMs that are still running after x amount of time?

# Get all hosts
$ESXiHost = Get-VMHost
Write-Host "Found ESXi Hosts:" $ESXiHost
