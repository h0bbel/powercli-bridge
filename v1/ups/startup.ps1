## Start environment up again after an UPS-triggered shutdown 
## Issues: https://github.com/h0bbel/powercli-bridge/issues

# Timer ref: https://arcanecode.com/2023/05/15/fun-with-powershell-elapsed-timers/
$processTimer = [System.Diagnostics.Stopwatch]::StartNew()
$endpoint = "UPS Startup"
$version = "0.1"
Write-Podehost "----------------------------------------------------------------" -ForegroundColor Cyan
Write-Podehost "$endpoint v$version UPS Startup event triggered - Running" -ForegroundColor Cyan

# Actual code goes here

## Read from state
Lock-PodeObject -ScriptBlock {
    Restore-PodeState -Path './states/shutdown_state.json'
    $names = Get-PodeStateNames
    Write-PodeHost "The following states have been restored: $names" -ForegroundColor Green
    $DRSLevel = Get-PodeState -Name 'DRSLevel' | ConvertFrom-Json
    $vCenterHost = Get-PodeState -Name 'vCenterHost' | ConvertFrom-Json
    $HAStatus = Get-PodeState -Name 'HAStatus' | ConvertFrom-Json
    $vCLSMode = Get-PodeState -Name 'vCLSMode' | ConvertFrom-Json
    $WhenEpoch = Get-PodeState -Name 'ExecutionTime' | ConvertFrom-Json

    # Issue: Something is wonky with the variables here. Must intestigate
    #Write-PodeHost "DRS Level: $DRSLevel, HA Status: $HAStatus, vCLS Mode: $vCLSMode, vCenterHost: $vCenterHost, Epoch: $WhenEpoch"

    #Get-PodeState 
    #Set-PodeState -Name 'vCenterHost' -Value @{ 'vCenterHost' = "$vCHost" } # | Out-Null
    #Set-PodeState -Name 'ExecutionTime' -Value @{ 'Timestamp' = "$EpochTime" } # | Out-Null
    #Save-PodeState -Path './states/shutdown_state.json'
    }


#Timer
$processTimer.Stop()
$ts = $processTimer.Elapsed
$elapsedTime = "{0:00}:{1:00}:{2:00}.{3:00}" -f $ts.Hours, $ts.Minutes, $ts.Seconds, ($ts.Milliseconds / 10)
Write-Podehost "All done - Total Elapsed Time $elapsedTime" -Foregroundcolor Green

#Done
Write-Podehost "Done: All defined UPS startup tasks have run, task completed." -ForegroundColor Cyan
Write-Podehost "----------------------------------------------------------------" -ForegroundColor Cyan
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint v$version";"message"= "NUT/UPS initiated startup completed in $elapsedTime."}
