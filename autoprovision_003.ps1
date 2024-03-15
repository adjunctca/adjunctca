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
    try {
        # Set registry key to run autopilot on next boot
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\AutoPilotPolicy" -Name "CloudAssignedOobeConfig" -Value 7 -Type DWord

        Write-Output "Deivce is now ready for Autopilot provisioning. The system will now restart"

        ##Time to restart
        #Restart-Computer
    } catch {
        Write-Error "An error occured preparing the device for Autopilot provisioning: $_"
    }
           
}





#Main Exec
Start-AutopilotProvisioning
