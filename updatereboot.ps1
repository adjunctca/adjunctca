#Set execution policy
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force -Verbose

$time = Get-Date -Format mm/dd/yyyy-hh:mm:ss
$scriptspath = "C:\scripts"

#Installing PSWindowsUpdate with(hopefully) no user intervention.
Set-PSRepository -Name PSGallery -Verbose -InstallationPolicy Trusted
Install-PackageProvider -Name NuGet -Force -Confirm:$false
Install-Module -Name PSWindowsUpdate -Verbose -Force -AllowClobber -SkipPublisherCheck -Confirm:$false

#Scripts Path Creation / Check
function Create-ScriptsDirectory {
if (-Not (Test-Path -Path $scriptspath)) {
    #If directory does not exist, create it 
    New-Item -Path $scriptspath -ItemType Directory
    Write-Output "$time - Directory: 'C:\scripts' does not exist." 
    Write-Output "$time - Creating directory: 'C:\scripts'"
} else {
    # If scripts directory already exists
    Write-Output "$time - Directory: 'C:\Scripts' already exists. Proceeding..."
    }
}

#Check/Create scripts directory
Create-ScriptsDirectory

#Importing PSWindowsUpdate
Import-Module PSWindowsUpdate

#Start transcript logging
Start-Transcript -Path "C:\scripts\updatereboot.log"

#Print script start time
Write-Output $time


#FUNCTION TO INSTALL NSSM
function Install-NSSM {
    $nssmPath = "C:\Windows\System32\nssm.exe"

    #Check if NSSM is already installed
    if (Test-Path $nssmPath) {
        Write-Host "$time - NSSM is already installed, skipping!"
        return
    }

    # Define URL and temp download path
    $url = "https://nssm.cc/release/nssm-2.24.zip"
    $tempZip = "C:\scripts\nssm-2.24.zip"
    $tempExtractPath = "C:\scripts\nssm-2.24"

    #Download NSSM Zip
    Write-Host "$time - Downloading NSSM..."
    Invoke-WebRequest -Uri $url -OutFile $tempZip

    #Extract Zip
    Write-Host "$time - Extracting NSSM..."
    Expand-Archive -LiteralPath $tempZip -DestinationPath $tempExtractPath -Force

    #Find the NSSM exec.
    $nssmExePath = Get-ChildItem -Path $tempExtractPath\nssm-2.24\win64\ -filter nssm.exe -Recurse | Select-Object -First 1 -ExpandProperty FullName

    #Move NSSM to System32
    if ($null -ne $nssmExePath) {
        Write-Host "$time - Installing NSSM to $nssmPath ..."
        Move-Item -Path $nssmExePath -Destination $nssmPath -Force
        Write-Host "$time - NSSM installation complete"
    } else {
        Write-Host "$time - Could not find NSSM executable in extracted files!!! I'm DONE!"

    }

    # Cleanup the downloaded and extracted files
    Remove-Item -Path $tempZip -Force
    Remove-Item -Path $tempExtractPath -Recurse -Force

}


#Function to create service which will run the update/reboot loop until all updates are complete
function Create-UpdateService {
    #Check if service already exists
    if (Get-Service -Name "autoupd" -ErrorAction SilentlyContinue) {
        Write-Host "$time - Service 'autoupd' already exists. Skipping service install!"
    } else {
        ###Create a service to run update script on startup###
        ###Requires no user logon, therefore actually works in OOBE environment###
        nssm install autoupd "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe" "C:\Windows\System32\updatereboot.ps1"
        nssm set autoupd Start SERVICE_AUTO_START
        Write-Host "$time - Service 'autoupd' created successfully"
    }
} 

#Function to remove auto update service when all updates are complete
function Remove-updateServiceAndNotify {
    # Remove the infinite update service!!!
    nssm remove autoupd confirm
    Write-Host "$time - Auto Update Service Removed..."
    Start-Process powershell.exe -ArgumentList "-Command Write-Host '$time - ALL UPDATES COMPLETE - SYSTEM IS READY FOR AUTOPILOT PROVISIONING!'; Read-Host -Prompt 'Press ENTER to close'"
}

function CheckAndInstallUpdates {
  # List of KBs to exclude
  $excludedKBs = @('KB5034441')

  # Get list of all available updates
  $updateAvailable = Get-WindowsUpdate -Verbose | Where-Object {
    # Filter out updates based on the excluded KB list
    $exclude = $false
    foreach ($kb in $excludedKBs) {
      if ($_.KBArticleIDs -contains $kb) {
        $exclude = $true
        break
      }
    }
    -not $exclude
  }

  if ($updateAvailable) {
    Write-Output "$time - Updates available. Installing..."
    foreach ($update in $updateAvailable) {
      Write-Output "Installing update: $($update.Title)"
      # Install each update individually
      Install-WindowsUpdate -Update $update -AcceptAll -Verbose -AutoReboot
    }
    Write-Output "$time - Rebooting to complete update installation..." 
    #Restart-Computer
  } else {
    Write-Output "$time - No updates available or all available updates are excluded." 
    Write-Output "$time - Removing service 'autoupd'"
    Remove-updateServiceAndNotify
    Write-Output "$time - ALL UPDATES COMPLETE. System is ready for Autopilot provisioning."
  }
}




#Install NSSM
Install-NSSM

#Create service for update + reboot loop
Create-UpdateService

#Run updates and reboot if necessary
CheckAndInstallUpdates

#Print script finish time
Write-Output $time

#stop transcript logging
Stop-Transcript
