param (
    [string]$network = "",
    [string]$steam_username = "",
    [string]$steam_password = "",
    [switch]$windows_update = $false,
    [switch]$manual_install = $false
)

$script_name = "utils.ps1"
. "C:\$script_name"

Disable-ScheduleWorkflow
Install-Steam
Enable-Audio
Add-DisconnectShortcut
Install-Steam
Set-Steam $steam_username $steam_password
Restart-Computer