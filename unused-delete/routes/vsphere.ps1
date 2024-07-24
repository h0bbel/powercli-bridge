# Standard Definitions
$APIcall = "vmtools/vsphere"
$DateVar = Get-Date -Format "dd/MM/yyyy HH:mm K"


# Define vCenter Server details
# Could this be included from external source?

$vCenterServer = "vc01.explabs.badunicorn.no"
$Username = "administrator@vsphere.local"
$Password = "Pronet2012!"

Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Connect to vCenter Server
try {
    Connect-VIServer -Server $vCenterServer -User $Username -Password $Password -ErrorAction Stop
    Write-Host "Connected to vCenter Server successfully."
}
catch {
    Write-Host "Failed to connect to vCenter Server: $($_.Exception.Message)" -ForegroundColor Red
    #Write-PodeJsonResponse -Value @{ "success" = "false;"message"= "Unable to connect to $vCenterServer";"timestamp"="$DateVar"}
    # Does not work.
    exit
}

# Temporary test VM
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


# Loop through powered on VMs.
# From https://www.virtu-al.net/2010/01/06/powercli-shutdown-your-virtual-infrastructure/
# For each of the VMs on the ESX hosts


Write-Host "Looping through all Powered ON VMs:"

Foreach ($VM in ($ESXiHost | Get-VM)){
    # Shutdown the guest cleanly
    Write-Host "Found Powered on VM:" $VM
    #$VM | Shutdown-VMGuest -Confirm:$false
}

# Add host shutdown?
# Chicken and egg situation?
# Anyway; Stop-VMHost should do it...

#Disconnect-VIServer * -Confirm:$false

# Pode Output
#Write-PodeTextResponse -Value "Doing things to VMs"
Write-PodeJsonResponse -Value @{ "success" = "true";"message"= "$APIcall was executed";"timestamp"="$DateVar"}


