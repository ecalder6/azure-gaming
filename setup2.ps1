param (
    [string]$admin_username = "",
    [string]$admin_password = "",
    [switch]$manual_install = $false
)

$script_name = "utils.psm1"
Import-Module "C:\$script_name"

Disable-ScheduleWorkflow
Disable-Devices
Disable-TCC
Enable-Audio
Install-VirtualAudio
Install-Steam
Add-AutoLogin $admin_username $admin_password
Restart-Computer