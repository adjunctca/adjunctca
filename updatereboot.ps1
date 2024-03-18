# Ensures execution policy allows script execution
if (!(Get-ExecutionPolicy -ListScript).Equals([System.Management.Automation.ExecutionPolicy]::RemoteSigned)) {
  Set-ExecutionPolicy RemoteSigned -Force
}

# Function to check for updates, install, and reboot if necessary
function CheckAndInstallUpdates {
  $updateAvailable = Get-WindowsUpdate -Available
  if ($updateAvailable) {
    Write-Output "Updates available. Installing..."
    Install-WindowsUpdate -AcceptAll -Quiet
    Restart-Computer -Wait -Force
    Write-Output "Rebooting to complete update installation..."
    # Since script execution is now via registry, no need to schedule a script restart after reboot
  } else {
    Write-Output "No updates available."
    # Check for existing registry key and remove if no updates
    Remove-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -ErrorAction SilentlyContinue
    Write-Output "Script complete. System is ready for Autopilot provisioning."
  }
}

# Function to add registry key for startup execution
function AddStartupKey {
  $scriptPath = $PSScriptPath  # Path to current script
  New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -PropertyType String -Value $scriptPath
  Write-Output "Registry key added to run script at startup."
}

# Function to remove registry key for startup execution
function RemoveStartupKey {
  Remove-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -ErrorAction SilentlyContinue
  Write-Output "Registry key removed for script startup execution."
}

# Check for existing registry key before running update checks
$existingKey = Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -ErrorAction SilentlyContinue

if (!$existingKey) {
  Write-Output "No existing registry key found. Adding one..."
  AddStartupKey
}

# Start the update check and install process
CheckAndInstallUpdates
