# Right now this works when called via http://localhost:8085/vmtools/vsphere
# It also runs at startup, which is a really bad idea.
# But not if Pode is started with pode start (HUH!)

# Standard Definitions
$DateVar = Get-Date -Format "dd/MM/yyyy HH:mm K"
$endpoint = "vmtools/versions"
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

$vCenterVersion = $Global:DefaultVIServers | select Name, Version, Build
Write-Host "vCenter version: $vCenterVersion"

$ESXiHosts = Get-VMHost

ForEach ( $ESXiHost in $ESXiHosts )
{
    # logic missing
    Write-Host "Processing $ESXiHost ...." -ForegroundColor Green
}



Disconnect-VIServer * -Confirm:$false

# Pode Output
#Write-PodeTextResponse -Value "Doing things to VMs"
#Write-PodeJsonResponse -Value @{ "success" = "true";"message"= "$endpoint was executed";"timestamp"="$DateVar"}

