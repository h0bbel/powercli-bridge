Write-Host "test1.ps1 running!"
#New-Item -Path . -Name "testfile1.txt" -ItemType "file" -Value "This is a text string."
New-Item /Users/h0bbel/powershell/powercli-bridge/test.txt -ItemType File -Force -Value 'I am created!'
