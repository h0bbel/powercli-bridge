# Wrapper script to environment variables are set before starting the Pode Server
<#
.SYNOPSIS
  Ensure environment variables are set before starting Pode server
.DESCRIPTION
  Runs setenv.ps1 to ensure environment variables are set before starting Pode server.
.LINK 
  https://github.com/h0bbel/powercli-bridge/
.EXAMPLE
  PS> .\wrapper.ps1
#>

$SetEnv = "$PSScriptRoot\setenv.ps1"
$PodeServer = "$PSScriptRoot\server.ps1"

if ($SetEnv) {
    & $SetEnv
    if ($PodeServer) {
        Write-Host "Starting Pode server"
        & $PodeServer
    } else {
        Write-Host "setenv.ps1 does not exist, exiting"
    exit
    }
}