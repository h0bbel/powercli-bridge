# This is a test of "dynamic" endpoints

# Pode Output
{
    $endpoint = "test2"
    Write-Host "This is endpoint:" $endpoint
    $DateVar = Get-Date -Format "dd/MM/yyyy HH:mm K"
    Write-PodeJsonResponse -Value @{ "success" = "true";"message"= "$endpoint was executed";"timestamp"="$DateVar"}
}