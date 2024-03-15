# Script Name: UpdateAndReboot.ps1

# Ensure running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    throw "This script requires Administrator privileges."
}

# Import the PSWindowsUpdate module
Import-Module PSWindowsUpdate

# Function to create a scheduled task that runs this script at startup
function Create-ScheduledTask {
    $action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-File `"$PSScriptRoot\UpdateAndReboot.ps1`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName "WindowsUpdateAndReboot" -Action $action -Trigger $trigger -Principal $principal -Description "Automatically checks for and installs Windows updates, then reboots if required." | Out-Null
}

# Function to check for and install updates
function Install-WindowsUpdates {
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

    if ($updates.Count -eq 0) {
        Write-Host "No more updates available. Removing scheduled task..."
        Unregister-ScheduledTask -TaskName "WindowsUpdateAndReboot" -Confirm:$false
    } else {
        Write-Host "Installing updates..."
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot | Out-Null
    }
}

# Check if the scheduled task exists, create if it doesn't
if (-not (Get-ScheduledTask -TaskName "WindowsUpdateAndReboot" -ErrorAction SilentlyContinue)) {
    Create-ScheduledTask
}

# Run the update installation function
Install-WindowsUpdates
