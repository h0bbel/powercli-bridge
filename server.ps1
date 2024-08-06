# Notes

# TODO:
#   All scripts should be located in /v1/
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

    # Setup apikey authentication to validate a user
    New-PodeAuthScheme -ApiKey | Add-PodeAuth -Name 'Authenticate' -Sessionless -ScriptBlock {
        param($key)
        
        $X_PODE_API_KEY = $env:X_PODE_API_KEY

        if ($key -eq $X_PODE_API_KEY) {
            return @{
                User = @{
                    'ID' ='Authorized'
                }
            }
        }

        # authentication failed - Not sure why returning json here does not work.
        Write-Host "Autentication failed. Reason: X-API-KEY from header invalid."
        return $null
    }

    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging -Levels Debug, Error, Warning, Informational, Verbose

    
    Add-PodeRoute -Method Get -Path '/api/v1/ups/shutdown' -Authentication 'Authenticate' -ScriptBlock {
         & "$PSScriptRoot\v1\ups\shutdown.ps1"           
    }

}   