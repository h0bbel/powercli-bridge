# Notes
#
# Seems the scripts in /endpoints/ and /routes/ get autorun when starting the server. Be careful. Not sure how to handle.
# Seems like just doing pode start, instead of starting server.ps1, actually fixes that somehow.
# TODO:
#   All scripts should be located in /endpoints/, needs cleanup
#   All scripts need a versioning scheme
#   Authentication / Secrets
#       Easiest to use JWT? https://pode.readthedocs.io/en/latest/Tutorials/Authentication/Methods/JWT/#parse-jwt
#   How to handle vCenter shutdown and then shutdown hosts?

# References:
#   https://bjornpeters.com/powershell/create-your-first-basic-api-in-powershell-using-pode/
#   https://www.virtu-al.net/2010/01/06/powercli-shutdown-your-virtual-infrastructure/
#   https://williamlam.com/2016/10/5-different-ways-to-run-powercli-script-using-powercli-core-docker-container.html
#   https://blog.mwpreston.net/2012/08/07/practise-makes-perfect-more-powercli-apc-powerchute-network-shutdown-goodness-now-with-power-on/
#   https://polarclouds.co.uk/esxi-rpi-ups-pt3/
#   

#Start Pode Server
Start-PodeServer {

    #Attach port 8085 to the local machine address and use HTTP protocol
    Add-PodeEndpoint -Address 0.0.0.0 -Port 8085 -Protocol HTTP

    # Seems like this actually autoruns! Careful! Not sure how to handle that!
    # Create route with script directly. Ref https://pode.readthedocs.io/en/latest/Tutorials/Routes/Overview/#parameters
    #Add-PodeRoute -Method Get -Path '/ping' -FilePath './routes/pong.ps1'

    # Create route with script directly. Ref https://pode.readthedocs.io/en/latest/Tutorials/Routes/Overview/#parameters
    #Add-PodeRoute -Method Get -Path '/ups' -FilePath './routes/ups.ps1'

    # Create route with script directly. Ref https://pode.readthedocs.io/en/latest/Tutorials/Routes/Overview/#parameters
    #Add-PodeRoute -Method Get -Path '/vmtools/vsphere' -FilePath './routes/vsphere.ps1'
 
    Add-PodeRoute -Method Get -Path '/v1/version' -ScriptBlock {
        $stuff = & "$PSScriptRoot\endpoints\version.ps1"            # This is stupid. Needs to be renamed
    }

    Add-PodeRoute -Method Get -Path '/v1/vmtools/vsphere' -ScriptBlock {
        $stuff = & "$PSScriptRoot\endpoints\vsphere.ps1"            # This is stupid. Needs to be renamed
    }

    Add-PodeRoute -Method Get -Path '/v1/vmtools/ups' -ScriptBlock {
        $stuff = & "$PSScriptRoot\endpoints\ups.ps1"            # This is stupid. Needs to be renamed
    }


    # Create endpoints dynamically for all .ps1 files in $FolderPath
    #$FolderPath = "endpoints"
    #$fileBaseNames = (Get-ChildItem $FolderPath\*.ps1).BaseName

    #Iterate through Files in $fileBaseNames and create endpoints
    #ForEach ($File in $fileBaseNames) {
    #    Write-Host "Processing file: $($File)"
    #    Write-Host "Endpoint:" "/endpoints/$File"
    #    Write-Host "Endpoint local path:" "$PSScriptRoot/endpoints/$File"
    #    Add-PodeRoute -Method Get -Path "/endpoints/$File" -FilePath "$PSScriptRoot/endpoints/$File.ps1"
    #}
}   