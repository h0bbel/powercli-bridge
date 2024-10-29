# Installer script for installing and configuring PowerCLI and Pode

<#
.SYNOPSIS
  Install required Powershell modules automatically
.DESCRIPTION
  Sets PSRepository to PSGallery, installes PowerCLI and Pode, unless they are already installed.
.LINK 
  https://github.com/h0bbel/powercli-bridge/
.EXAMPLE
  PS> .\install.ps1
#>

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

if(-not (Get-Module Pode -ListAvailable)){
    Write-Host "Installing Pode." -ForegroundColor Cyan
    Install-Module Pode -Scope CurrentUser -Force
    }
    else {
        Write-Host "Pode already installed." -ForegroundColor Green
    }
