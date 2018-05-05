param (
    [string]$network = "",
    [string]$steam_username = "",
    [string]$steam_password = "",
    [string]$admin_username = "",
    [string]$admin_password = "",
    [switch]$windows_update = $false,
    [switch]$manual_install = $false
)

function Get-UtilsScript ($script_name) {
    $url = "https://raw.githubusercontent.com/ecalder6/azure-gaming/master/$script_name"
    Write-Host "Downloading utils script from $url"
    [Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    $webClient = new-object System.Net.WebClient
    $webClient.DownloadFile($url, "C:\$script_name")
}

$script_name = "utils.psm1"
Get-UtilsScript $script_name
Import-Module "C:\$script_name"

if ($windows_update) {
    Update-Windows
}
Update-Firewall
Disable-Defender
Disable-ScheduledTasks
Disable-IPv6To4
if ($manual_install) {
    Disable-InternetExplorerESC
    Edit-VisualEffectsRegistry
}
Add-DisconnectShortcut

Install-Chocolatey
Install-VPN
Join-Network $network
Install-NSSM

Install-NvidiaDriver $manual_install
Set-ScheduleWorkflow $steam_username $steam_password $admin_username $admin_password $manual_install
Restart-Computer
