$content=@"
Write-Output '>>> Waiting for GA Service (RdAgent) to start ...'
while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }
Write-Output '>>> Waiting for GA Service (WindowsAzureTelemetryService) to start ...'
Write-Output '>>> Waiting for GA Service (WindowsAzureGuestAgent) to start ...'
while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }
Write-Output '>>> skipping sysprep ...'
"@

Set-Content c:\DeprovisioningScript.ps1 -Value $content
#generate password and store in keyvault would be best
new-localuser -Name $username -Password $password
Add-LocalGroupMember -Group Administrators  -Member $username