# Wrapper script to ensure that prerequisites are installed
# and environment variables are set before starting the Pode Server
# TODO: Add checks before install?

# Install
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

if(-not (Get-Module VMware.PowerCLI -ListAvailable)){
    Write-Host "Installing PowerCLI." -ForegroundColor Cyan
    Install-Module VMware.PowerCLI -Scope CurrentUser -Force
    }
    else {
        Write-Host "PowerCLI already installed." -ForegroundColor Green
    }

#Install-Module VMware.PowerCLI -Scope AllUsers

# Configure PowerCLI
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -Confirm:$false | Out-Null
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Install Pode
#Install-Module -Name Pode -Scope AllUsers

if(-not (Get-Module Pode -ListAvailable)){
    Write-Host "Installing Pode." -ForegroundColor Cyan
    Install-Module Pode -Scope CurrentUser -Force
    }
    else {
        Write-Host "Pode already installed." -ForegroundColor Green
    }

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