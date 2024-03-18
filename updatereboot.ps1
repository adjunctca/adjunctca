### Set execution policy
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force -Verbose

### Installing PSWindowsUpdate with(hopefully) no user intervention.
Set-PSRepository -Name PSGallery -Verbose -InstallationPolicy Trusted
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name PSWindowsUpdate -Verbose -Force -AllowClobber -SkipPublisherCheck -Confirm:$false

### Importing PSWindowsUpdate
Import-Module PSWindowsUpdate

$logFile = (Get-Location).Path + "\updatereboot.log"

# Function to check for updates, install, and reboot if necessary
function CheckAndInstallUpdates {
  $updateAvailable = Get-WindowsUpdate -Verbose
  if ($updateAvailable) {
    Write-Output "Updates available. Installing..." >> $logFile
    Get-Windowsupdate -Install -AcceptAll -AutoReboot -Verbose
    Write-Output "Rebooting to complete update installation..." >> $logFile
  } else {
    Write-Output "No updates available." >> $logFile
    # Check for existing registry key and remove if no updates
    Remove-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -ErrorAction SilentlyContinue -Verbose
    Write-Output "Script complete. System is ready for Autopilot provisioning." >> $logFile
    Write-Output "Removing script from startup/run registry key"
  }
}

# Function to add registry key for startup execution
function AddStartupKey {
  $scriptPath = "C:\scripts\updatereboot.ps1"  # Path to current script
  New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -PropertyType String -Value $scriptPath -Verbose
  Write-Output "Registry key added to run script at startup." >> $logFile
}

# Function to remove registry key for startup execution
function RemoveStartupKey {
  Remove-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -ErrorAction SilentlyContinue -Verbose
  Write-Output "Registry key removed for script startup execution." >> $logFile
}

# Check for existing registry key before running update checks
$existingKey = Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "Pre-AutoPilotUpdate" -ErrorAction SilentlyContinue -Verbose

if (!$existingKey) {
  Write-Output "No existing registry key found. Adding one..." >> $logFile
  AddStartupKey
}




# Start the update check and install process
CheckAndInstallUpdates

Write-Output "*" >> $logFile
$scriptOutput = & CheckAndInstallUpdates
Write-Output $scriptOutput >> $logFile
