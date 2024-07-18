# Currently not working

    # Define vCenter Server details
    $vCenterServer = "192.168.5.30"
    $Username = "administrator@vsphere.local"
    $Password = "fr3Kecap!"

    #Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -Confirm:$false
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null


    $endpoint = "listVMs"
    Write-Host "This is endpoint:" $endpoint
    $DateVar = Get-Date -Format "dd/MM/yyyy HH:mm K"

#Connect to vCenter Server
    try {
        Connect-VIServer -Server $vCenterServer -User $Username -Password $Password -ErrorAction Stop
        Write-Host "Connected to vCenter Server successfully."
    }
    catch {
        Write-Host "Failed to connect to vCenter Server: $($_.Exception.Message)" -ForegroundColor Red
        exit
    }
    #$vms =  Get-VM | Select-Object -Property Name, VMhost
    $vms =  Get-VM | Select-Object -Property Name

    Write-Host $vms

    # This doesn't really return the VM list ($vms) just prints it on screen. How do I fix that? Get the output into the "master" script?

    Disconnect-VIServer * -Confirm:$false

# Pode Output
{

    #Write-PodeJsonResponse -Value @{ 'value' = 'pong';"success" = "true";"message"= "$endpoint was executed";"timestamp"="$DateVar"}
    #Write-PodeJsonResponse -Value @{ 'value' = $vms;"success" = "true";"message"= "$endpoint was executed";"timestamp"="$DateVar"}
}


