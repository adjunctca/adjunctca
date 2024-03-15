Set-ExecutionPolicy Bypass -Scope CurrentUser -Force -Verbose
Set-PSRepository -Name PSGallery -Verbose -InstallationPolicy Trusted 
Install-Module -Name PSWindowsUpdate -Verbose -Force -AllowClobber -SkipPublisherCheck -Confirm:$false


Import-Module PSWindowsUpdate

#define exclusions
$exclusions = @("KB5011048")

### FUNCTION STARTS AUTOPILOT PROVISIONING ###
function Start-AutopilotProvisioning {
	#provisioning logic here
	Write-Output "starting Autopilot Provisioning..."
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\AutoPilot"
    $registryProperty = "CloudAssignedOobeConfig"
    $registryValue = 7

    #Check if the registry path exists
    if (-not (Test-Path $registryPath)) {
        #Path does not exist, so create it!
        New-Item -Path $registryPath -Force | Out-Null
        Write-Host "Registry path did not exist and has been created!"
    }
    try {
        # Set registry key to run autopilot on next boot
        Set-ItemProperty -Path $registryPath -Name $registryProperty -Value $registryValue -Type DWord

        Write-Output "Registry Value set for Autopilot Provisioning."
        Write-Output "Deivce is now ready for Autopilot provisioning. The system will now restart!"

        ##Time to restart
        #Restart-Computer
    } catch {
        Write-Error "An error occured preparing the device for Autopilot provisioning: $_"
    }
           
}





#Main Exec
Start-AutopilotProvisioning
