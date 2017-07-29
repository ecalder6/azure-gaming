param (
    [string]$network = "",
    [string]$steam_username = "",
    [string]$steam_password = "",
    [switch]$windows_update = $false,
    [switch]$manual_install = $false
)

function Get-UtilsScript ($script_name) {
    $url = "https://raw.githubusercontent.com/ecalder6/azure-gaming/master/$script_name"
    Write-Host "Downloading utils script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "C:\$script_name")
    
}

$script_name = "utils.ps1"
Get-UtilsScript $script_name
. "C:\$script_name"

if ($windows_update) {
    InlineScript {Update-Windows}
}
Update-Firewall
Disable-Defender
Disable-ScheduledTasks
Disable-IPv6To4

Install-Chocolatey
Install-VPN
Join-Network $network
Install-NSSM

Install-NvidiaDriver $manual_install
Set-ScheduleWorkflow $steam_username $steam_password
Restart-Computer
