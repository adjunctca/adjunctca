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

### FUNCTION TO INSTALL NSSM ###
function Install-NSSM {
    $nssmPath = "C:\Windows\System32\nssm.exe"

    #Check if NSSM is already installed
    if (Test-Path $nssmPath) {
        Write-Host "NSSM is already installed, skipping!"
        return
    }

    # Define URL and temp download path
    $url = "https://nssm.cc/release/nssm-2.24.zip"
    $tempZip = "C:\scripts\nssm-2.24.zip"
    $tempExtractPath = "C:\scripts\nssm-2.24"

    #Download NSSM Zip
    Write-Host "Downloading NSSM..."
    Invoke-WebRequest -Uri $url -OutFile $tempZip

    #Extract Zip
    Write-Host "Extracting NSSM..."
    Expand-Archive -LiteralPath $tempZip -DestinationPath $tempExtractPath -Force

    #Find the NSSM exec.
    $nssmExePath = Get-ChildItem -Path $tempExtractPath\nssm-2.24\win64\ -filter nssm.exe -Recurse | Select-Object -First 1 -ExpandProperty FullName

    #Move NSSM to System32
    if ($null -ne $nssmExePath) {
        Write-Host "Installing NSSM to $nssmPath ..."
        Move-Item -Path $nssmExePath -Destination $nssmPath -Force
        Write-Host "NSSM installation complete"
    } else {
        Write-Host "Could not find NSSM executable in extracted files!!! I'm DONE!"

    }

    # Cleanup the downloaded and extracted files
    Remove-Item -Path $tempZip -Force
    Remove-Item -Path $tempExtractPath -Recurse -Force

}


### Function to create service which will run the update/reboot loop until all updates are complete ###
function Create-UpdateService {
    #Check if service already exists
    if (Get-Service -Name "autoupd" -ErrorAction SilentlyContinue) {
        Write-Host "Service 'autoupd' already exists. Skipping service install!"
    } else {
        ###create a service to run update script on startup 
        ###requires no user logon, therefore actually works in OOBE environment
        nssm install autoupd "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" "C:\scripts\updatereboot.ps1"
        nssm set autoupd Start SERVICE_AUTO_START
        Write-Host "Service 'autoupd' created successfully"
    }
} 

### Function to remove auto update service when all updates are complete ###
function Remove-updateServiceAndNotify {
    # Remove the infinite update service!!!
    nssm remove autoupd confirm
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
    Write-Output "$time - Removing service 'autoupd'"
    Remove-updateServiceAndNotify
    Write-Output "$time - Script complete. System is ready for Autopilot provisioning."
  }
}


### Install NSSM
Install-NSSM

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
