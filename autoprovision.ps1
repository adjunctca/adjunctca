$taskName = "AutoUpdateAutoPilot"
$taskPath = "\\"
$scriptPath = "C:\scripts\autoprovision.ps1"

### Function to create a scheduled task that runs this script at startup
### This will be created and utilized repeatedly until no new updates are detected
### When there are no new updates detected, this task should automatically be removed
### Removal of this scheduled task SHOULD always be proceeded by autopilot provisioning
function CreateScheduledTask {
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Automate Windows updates and start Autopilot provisioning."
    Write-Host "Scheduled task created to automate updates and start Autopilot provisioning."
}

### Function to initiate Windows Autopilot provisioning
### Modifies necessary registry item and triggers a reboot- after which the autopilot provisioning should run immediately
function Start-AutopilotProvisioning {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\Autopilot" -Name "CloudAssignedOobeConfig" -Value 7 -Type DWord
    Write-Host "Autopilot provisioning initiated. The system will now restart."
    Restart-Computer
}

###Primary function to run windows update
function Install-WindowsUpdates {
    ###Something like this
    ###Get-Windowsupdate -AcceptAll -Install

    $updatesRequired = $false ### Figure out some logic to produce return code for yes/no 
    ### If no further updats are required, do the following:
    ### Unregister scheduled task for update/reboot loop
    ### Finally start the autopilot provisioning with current enrollment/profile
    if (-not $updatesRequired) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "No more updates required. Scheduled task removed."
        Start-AutopilotProvisioning # Start Autopilot provisioning
    ### If there were still updates to install, continue the update/reboot loop
    } else {
        Write-Host "Updates installed, system will reboot and check again."
        Restart-Computer
    }
}

### Check if the scheduled task exists, if not, create it
### Used to create the initial loop which will:
### Check for updates, install, reboot if necessary, rinse, repeat...
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -eq $taskName} | Select-Object -ExpandProperty TaskName
if (-not $taskExists) {
    CreateScheduledTask
}

### Ensure script is running with Administrator privileges
### Maybe not necessary, can't hurt though?
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges."
    exit
}

### The function which will either run updates and reboot, or begin autopilot provisioning if there are no further updates
### See function declaration above
Install-WindowsUpdates
