$taskName = "InstallWindowsUpdatesAndStartAutopilot"
$taskPath = "\\"
$scriptPath = "C:\scripts\autoprovision.ps1"

# Function to create a scheduled task that runs this script at startup
function CreateScheduledTask {
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Automate Windows updates and start Autopilot provisioning."
    Write-Host "Scheduled task created to automate updates and start Autopilot provisioning."
}

# Function to initiate Windows Autopilot provisioning
function Start-AutopilotProvisioning {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\Autopilot" -Name "CloudAssignedOobeConfig" -Value 7 -Type DWord
    Write-Host "Autopilot provisioning initiated. The system will now restart."
    Restart-Computer
}

# Main function to install Windows updates
function Install-WindowsUpdates {
    # Your update installation logic here (simplified for brevity)

    $updatesRequired = $false # Placeholder for actual update check logic

    if (-not $updatesRequired) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "No more updates required. Scheduled task removed."
        Start-AutopilotProvisioning # Start Autopilot provisioning
    } else {
        Write-Host "Updates installed, system will reboot and check again."
        Restart-Computer
    }
}

# Check if the scheduled task exists, if not, create it
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -eq $taskName} | Select-Object -ExpandProperty TaskName
if (-not $taskExists) {
    CreateScheduledTask
}

# Ensure script is running with Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges."
    exit
}

Install-WindowsUpdates
