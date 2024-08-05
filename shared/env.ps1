$vCenterVMName = $Env:vCenterVMName                 # vCenter VM name - used to exclude the vCenter VM in the shutdown procedure
$vCenterServerFQDN = $Env:vCenterServerFQDN         # vCenter FQDN name, used for the PowerCLI connection
$vCenterUsername = $Env:vCenterUsername             # vCenter username, ex. administrator@vsphere.local
$vCenterPassword = $Env:vCenterPassword             # $vCenterUsername Password

$X_PODE_API_KEY = $Env:X_PODE_API_KEY               # API Key