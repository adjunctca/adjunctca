### Set execution policy
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force -Verbose

### Installing PSWindowsUpdate with(hopefully) no user intervention.
Set-PSRepository -Name PSGallery -Verbose -InstallationPolicy Trusted 
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name PSWindowsUpdate -Verbose -Force -AllowClobber -SkipPublisherCheck -Confirm:$false

### Importing PSWindowsUpdate
Import-Module PSWindowsUpdate

$PSScriptPath = "C:\scripts\windowsupdatereboot.ps1"


### Function to check for updates, install, and reboot if necessary
function CheckAndInstallUpdates {
  $updateAvailable = Get-WindowsUpdate -Verbose
  if ($updateAvailable) {
    Write-Output "Updates available. Installing..."
    Get-WindowsUpdate -Install -AcceptAll -Verbose -AutoReboot
    #Restart-Computer -Wait -Force
    Write-Output "Rebooting to complete update installation..."
    ### Schedule script execution again after reboot using Shutdown.exe
    #Shutdown /r /t 60 /c "Script will restart to check for more updates after 60 seconds."
  } else {
    Write-Output "No updates available."
    ### Check for existing scheduled task and remove if no updates
    Write-Output "Unregistering Scheduled task"
    Unregister-ScheduledTask -TaskName "Pre-AutoPilot-Update" -ErrorAction SilentlyContinue -Confirm:$false -Verbose
    Write-Output "Script complete. System is ready for Autopilot provisioning."
  }
}

### Function to create a scheduled task to run the script at startup
function CreateScheduledTask {
  ### Define scheduled task configuration
  $taskName = "Pre-AutoPilot-Update"
  $trigger = New-ScheduledTaskTrigger -AtStartup
  #$trigger = "-Trigger -Daily -AtStartup"
  $action = New-ScheduledTaskAction -Execute -Path $PSScriptPath

  try {
    ### Create scheduled task with elevated privileges
    Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -RunLevel Highest -Force
    Write-Output "Scheduled task created to run script at startup."
  } catch {
    Write-Error "Failed to create scheduled task: ($_.Exception.Message)"
  }
}

### Check for existing scheduled task before running update checks
$existingTask = Get-ScheduledTask -TaskName "Pre-AutoPilot-Update" -ErrorAction SilentlyContinue

if (!$existingTask) {
  Write-Output "No existing scheduled task found. Creating one..."
  CreateScheduledTask
}

### Start the update check and install process
CheckAndInstallUpdates

