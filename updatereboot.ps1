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
### start time output
Write-Output $time

# Function to check for updates, install, and reboot if necessary
function CheckAndInstallUpdates {
  $updateAvailable = Get-WindowsUpdate -Verbose
  if ($updateAvailable) {
    Write-Output "$time - Updates available. Installing..."
    Get-Windowsupdate -Install -AcceptAll -AutoReboot -Verbose
    Write-Output "$time - Rebooting to complete update installation..." 
  } else {
    Write-Output "$time - No updates available." 
    Write-Output "$time - Removing startup Script CMD"
    ### Remove Startup CMD to break reboot/update loop
    Remove-Item -Path 'C:\Users\defaultuser0\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startupdates.cmd' -ErrorAction Continue
    Write-Output "$time - Script complete. System is ready for Autopilot provisioning."
  }
}

# function to add startup cmd
function Write-StartupFile {
    $filePath = "C:\Users\defaultuser0\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startupdates.cmd"
    $linesToWrite = @(
        "Powershell -Command Set-ExecutionPolicy Bypass -Force",
        "Powershell C:\scripts\updatereboot.ps1"
    )

    ### Ensure Parents Directory already exists
    $parentDir = Split-Path $filePath -Parent
    if (!(Test-Path $parentDir)) {
    New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }

    # Create or overwrite the file
    $null = New-Item $filePath

    # Write lines out to file
    $linesToWrite | Out-File -FilePath $filePath -Encoding UTF8 -Append
}

if (Test-Path "C:\Users\defaultuser0\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\startupdates.cmd") {
    Write-Output "startupdates.cmd already exists, proceeding"
} else {
    Write-Output "startupdates.cmd does not already exist, creating startupdates.cmd now!"
    Write-StartupFile
}

# Start the update check and install process
CheckAndInstallUpdates

### finish time output
Write-Output $time

### stop transcript logging
Stop-Transcript
