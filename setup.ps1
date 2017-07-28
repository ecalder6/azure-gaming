param (
    [string]$network = "",
    [string]$steam_username = "",
    [string]$steam_password = "",
    [switch]$windows_update = $false,
    [switch]$manual_install = $false
)

function Get-UtilsScript {
    $script_name = "utils.ps1"
    $url = "https://raw.githubusercontent.com/ecalder6/azure-gaming/master/$script_name"
    Write-Host "Downloading utils script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "C:\$script_name")
    . "C:\$script_name"
}

workflow Set-Computer($network, $steam_username, $steam_password, $manual_install, $windows_update) {
    sequence {
        Get-UtilsScript
        if ($windows_update) {
            Update-Windows
        }
        Update-Firewall
        Disable-Defender
        Disable-ScheduledTasks

        Install-Chocolatey
        Install-VPN
        Join-Network $network
        Install-NSSM

        Install-NvidiaDriver $manual_install

        Add-DummyUser

        Set-ScheduleWorkflow
        Restart-Computer
    }
}

Set-Computer $network $steam_username $steam_password $manual_install $windows_update -JobName SetComputer