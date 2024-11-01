FROM photon:5.0
LABEL maintainer="christian@drible.net"
RUN tdnf makecache && \
	tdnf -y distro-sync && \
	tdnf repolist && \
	tdnf -y update
RUN tdnf -y install powershell
RUN pwsh -command "Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted"
RUN pwsh -command "Install-Module VMware.PowerCLI -Scope AllUsers"
RUN pwsh -command "Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP \$false -Confirm:\$false | Out-Null"
RUN pwsh -command "Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:\$false | Out-Null"
RUN pwsh -command "Install-Module -Name Pode -Scope AllUsers"
RUN pwsh -command "Get-PowerCLIVersion"
RUN pwsh -command "Get-PodeVersion"
COPY . /usr/local/bin/powercli-bridge
EXPOSE 8085
CMD ["/usr/bin/pwsh", "/usr/local/bin/powercli-bridge/server.ps1"]