Import-Module PSWindowsUpdate

#define exclusions
$exclusions = @("KB5011048")

function Check-ForUpdates {
	$availableUpdate = Get-WindowsUpdate -MicrosoftUpdate | Where-Object {
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

Check-ForUpdates