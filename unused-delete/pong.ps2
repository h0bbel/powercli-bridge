# This is a test of "dynamic" endpoints

# Pode Output
{
    $endpoint = "pong"
    Write-Host "This is endpoint:" $endpoint
    $DateVar = Get-Date -Format "dd/MM/yyyy HH:mm K"
    Write-PodeJsonResponse -Value @{ 'value' = 'pong';"success" = "true";"message"= "$endpoint was executed";"timestamp"="$DateVar"}
}
