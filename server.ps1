# Notes
#
# Do not start server.ps1 directly, as it autoruns the endpoints
# Seems like just doing pode start, instead of starting server.ps1, actually fixes that somehow.
# Or does it? Seems to be OK now, so perhaps I did something very weird. 18.07.2024

# TODO:
#   All scripts should be located in /endpoints/, needs cleanup
#   All scripts need a versioning scheme
#   Authentication / Secrets
#       Easiest to use JWT? https://pode.readthedocs.io/en/latest/Tutorials/Authentication/Methods/JWT/#parse-jwt
#   How to handle vCenter shutdown and then shutdown hosts?
#   Look into tasks? Perhaps a better way to run async? (eg. no timeout issues)
#   Output from scripts not until end... any way to force it to return early?

# Issues:
#   Configured timeout value in server1.psd - Did not help?


# References:
#   https://bjornpeters.com/powershell/create-your-first-basic-api-in-powershell-using-pode/
#   https://www.virtu-al.net/2010/01/06/powercli-shutdown-your-virtual-infrastructure/
#   https://williamlam.com/2016/10/5-different-ways-to-run-powercli-script-using-powercli-core-docker-container.html
#   https://blog.mwpreston.net/2012/08/07/practise-makes-perfect-more-powercli-apc-powerchute-network-shutdown-goodness-now-with-power-on/
#   https://polarclouds.co.uk/esxi-rpi-ups-pt3/
#   

# Set PowerCLI Configuration silently

Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -DisplayDeprecationWarnings $false -Confirm:$false | Out-Null


#Start Pode Server
Start-PodeServer {

    #Attach port 8085 to the local machine address and use HTTP protocol
    Add-PodeEndpoint -Address 0.0.0.0 -Port 8085 -Protocol HTTP

    # Auth test - Needs cleanup. Check API key from config file instead?

    # setup apikey authentication to validate a user
    New-PodeAuthScheme -ApiKey | Add-PodeAuth -Name 'Authenticate' -Sessionless -ScriptBlock {
        param($key)
        
        $X_PODE_API_KEY = '123456' # Should be changed to a ENV variable or some other secret.
        
        #Write-Host "PODEAPIKEY:" $PODEAPIKEY
        # here you'd check a real storage, this is just for example
        if ($key -eq $X_PODE_API_KEY) {
            return @{
                User = @{
                    'ID' =''
                    #'Name' = 'Morty'
                    #'Type' = 'Human'
                }
            }
        }

        # authentication failed
        Write-Host "Autentication failed. Reason: API Key from header invalid:" $key "X_PODE_API_KEY:" $X_PODE_API_KEY
        return $null
    }
    
    # Create route with script directly. Ref https://pode.readthedocs.io/en/latest/Tutorials/Routes/Overview/#parameters
    #Add-PodeRoute -Method Get -Path '/ping' -FilePath './routes/pong.ps1'

    # Create route with script directly. Ref https://pode.readthedocs.io/en/latest/Tutorials/Routes/Overview/#parameters
    #Add-PodeRoute -Method Get -Path '/ups' -FilePath './routes/ups.ps1'

    # Create route with script directly. Ref https://pode.readthedocs.io/en/latest/Tutorials/Routes/Overview/#parameters
    #Add-PodeRoute -Method Get -Path '/vmtools/vsphere' -FilePath './routes/vsphere.ps1'

    #Add-PodeRoute -Method Get -Path '/v1/version' -Authentication 'Authenticate' -ScriptBlock {
    #    $stuff = & "$PSScriptRoot\endpoints\version.ps1"            # This is stupid. Needs to be renamed
    #}

    #Add-PodeRoute -Method Get -Path '/v1/vmtools/vsphere' -Authentication 'Authenticate' -ScriptBlock {
    #   # $stuff = & "$PSScriptRoot\endpoints\vsphere.ps1"            # This is stupid. Needs to be renamed
    #}

    Add-PodeRoute -Method Get -Path '/v1/vmtools/ups' -Authentication 'Authenticate' -ScriptBlock {
        $stuff = & "$PSScriptRoot\endpoints\ups.ps1"            # This is stupid. Needs to be renamed
    }

    #Add-PodeRoute -Method Get -Path '/v1/vmtools/versions' -Authentication 'Authenticate' -ScriptBlock {
    #    # $stuff = & "$PSScriptRoot\endpoints\versions.ps1"            # This is stupid. Needs to be renamed
    #}

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