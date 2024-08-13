# Notes
# References:
#   https://bjornpeters.com/powershell/create-your-first-basic-api-in-powershell-using-pode/
#   https://www.virtu-al.net/2010/01/06/powercli-shutdown-your-virtual-infrastructure/
#   https://williamlam.com/2016/10/5-different-ways-to-run-powercli-script-using-powercli-core-docker-container.html
#   https://blog.mwpreston.net/2012/08/07/practise-makes-perfect-more-powercli-apc-powerchute-network-shutdown-goodness-now-with-power-on/
#   https://polarclouds.co.uk/esxi-rpi-ups-pt3/
#   

#https://learn.microsoft.com/en-us/powershell/scripting/developer/help/syntax-of-comment-based-help?view=powershell-7.4

<#
.SYNOPSIS
  Starts the Pode server and loads the configured routes
.DESCRIPTION
  Starts the Pode server and loads the configured routes
.LINK 
  https://github.com/h0bbel/powercli-bridge/
.EXAMPLE
  PS> .\server.ps1
#>

# Set PowerCLI Configuration silently
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -DisplayDeprecationWarnings $false -Confirm:$false | Out-Null

#Start Pode Server
Start-PodeServer {

    #Attach port 8085 to the local machine address and use HTTP protocol
    #Add-PodeEndpoint -Address 0.0.0.0 -Port 8085 -Protocol HTTP

    #Attach port 8085 to the local machine address and use HTTPS protocol with a self-signed cert
    Add-PodeEndpoint -Address * -Port 8085 -Protocol Https -SelfSigned # Test HTTPS

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

    # Configure Pode

    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging -Levels Debug, Error, Warning, Informational, Verbose
    
    # Add Routes
    Add-PodeRoute -Method Get -Path '/api/v1/ups/shutdown' -Authentication 'Authenticate' -ScriptBlock {
         & "$PSScriptRoot\v1\ups\shutdown.ps1"           
    }

    Add-PodeRoute -Method Get -Path '/api/v1/ups/startup' -Authentication 'Authenticate' -ScriptBlock {
        & "$PSScriptRoot\v1\ups\startup.ps1"           
   }

}   