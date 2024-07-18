$endpoint = "UPS"
$version = "0.1"
Write-PodeJsonResponse -Value @{ "success" = "true";"version"= "$endpoint version:$version";"message"= "This is where the UPS logic goes"}
