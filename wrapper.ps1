# Wrapper script to ensure environment variables are set before starting the Pode Server

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