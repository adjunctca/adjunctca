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
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\AutoPilot" -Name "CloudAssignedOobeConfig" -Value 7 -Type DWord

        Write-Output "Deivce is now ready for Autopilot provisioning. The system will now restart"

        ##Time to restart
        Restart-Computer
    } catch {
        Write-Error "An error occured preparing the device for Autopilot provisioning: $_"
    }
           
}

### Function checks for windows updates (with exclusions) ###
function Check-ForUpdates {
	$availableUpdate = Get-WindowsUpdate -Verbose | Where-Object {
		$update = $_
		$isExcluded = $false
		foreach ($exclusion in $exclusions) {
			if ($update.Title -match $exclusion) {
				$isExcluded = $true
				break
			}
		}
		-not $isExcluded
	}

	if ($availableUpdate.Count -eq 0) {
		Write-Output "No relevant updates found or only exclusions remain."
		return $false
	} else {
		Write-Output "$($availableUpdates.Count) updates found that are not in the exclusions list."
	}
}


### Installs updates, if any are available ###
### If no updates are available, begins autopilot provisioning ###
function Install-WindowsUpdates {
	$updateExist = Check-ForUpdates

	if ($updatesExist) {
		Write-Host "Installing Updates..."
		Get-WindowsUpdate -acceptall -install -verbose
	} else {
		Write-Host "No updates to install. Proceeding with Autopilot provisioning."
		Start-AutopilotProvisioning
	}
}



#Main Exec
Install-WindowsUpdates
