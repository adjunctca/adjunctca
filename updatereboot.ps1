### Set execution policy
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force -Verbose
$time = Get-Date -Format mm/dd/yyyy-hh:mm:ss
### Installing PSWindowsUpdate with(hopefully) no user intervention.
Set-PSRepository -Name PSGallery -Verbose -InstallationPolicy Trusted
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name PSWindowsUpdate -Verbose -Force -AllowClobber -SkipPublisherCheck -Confirm:$false

### Importing PSWindowsUpdate
Import-Module PSWindowsUpdate
### Start transcript logging
Start-Transcript -Path "C:\scripts\updatereboot.log"
### Output start time
Write-Output $time


### Function to create service which will run the update/reboot loop until all updates are complete ###
function Create-UpdateService {
    #Check if service already exists
    if (Get-Service -Name "apautoupdate" -ErrorAction SilentlyContinue) {
        Write-Host "Service 'apautoupdate' already exists. Proceeding!"
    } else {
        ###create a service to run update script on startup 
        ###requires no user logon, therefore actually works in OOBE environment
        sc.exe create apautoupdate binPath="C:\scripts\updatereboot.ps1" start=auto

        Write-Host "Service 'apautoupdate' created successfully"
    }
} 

### Function to remove auto update service when all updates are complete ###
function Remove-updateServiceAndNotify {
    # Remove the infinite update service!!!
    sc.exe delete apautoupdate
    Write-Host "Auto Update Service Removed..."
    Start-Process powershell.exe -ArgumentList "-Command Write-Host 'ALL UPDATES COMPLETE - SYSTEM IS READY FOR AUTOPILOT PROVISIONING!'; Read-Host -Prompt 'Press ENTER to close'"
}

# Function to check for updates, install, and reboot if necessary
function CheckAndInstallUpdates {
  $updateAvailable = Get-WindowsUpdate -Verbose
  if ($updateAvailable) {
    Write-Output "$time - Updates available. Installing..."
    Get-Windowsupdate -Install -AcceptAll -Verbose -AutoReboot
    Write-Output "$time - Rebooting to complete update installation..." 
    #Restart-Computer
  } else {
    Write-Output "$time - No updates available." 
    Write-Output "$time - Removing service 'apautoupdate'"
    Remove-updateServiceAndNotify
    Write-Output "$time - Script complete. System is ready for Autopilot provisioning."
  }
}



### Run Auto Update service function
Create-UpdateService

### Check for updates
### If updates available, install and reboot ###
### When updates complete, delete auto update service and output done message ###
CheckAndInstallUpdates

### finish time output
Write-Output $time

### stop transcript logging
Stop-Transcript
