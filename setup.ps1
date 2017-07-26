function Update-Windows {
    $url = "https://gallery.technet.microsoft.com/scriptcenter/Execute-Windows-Update-fc6acb16/file/144365/1/PS_WinUpdate.zip"
    $compressed_file = "PS_WinUpdate.zip"
    $update_script = "PS_WinUpdate.ps1"

    Write-Host "Downloading Windows Update Powershell Script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "$PSScriptRoot\$compressed_file")

    Write-Host "Extracting Windows Update Powershell Script"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\" -Force

    Write-Host "Running Windows Update"
    Invoke-Expression $PSScriptRoot\$update_script
}

function Update-Firewall {
    Write-Host "Enable ICMP Ping in Firewall."
    Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True
}

function Disable-Defender {
    Write-Host "Disable Windows Defender real-time protection."
    Set-MpPreference -DisableRealtimeMonitoring $true
}

function Disable-ScheduledTasks {
    Write-Host "Disable unnecessary scheduled tasks"
    Disable-ScheduledTask -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag'
    Disable-ScheduledTask -TaskName 'ProactiveScan' -TaskPath '\Microsoft\Windows\Chkdsk'
    Disable-ScheduledTask -TaskName 'Scheduled' -TaskPath '\Microsoft\Windows\Diagnosis'
    Disable-ScheduledTask -TaskName 'SilentCleanup' -TaskPath '\Microsoft\Windows\DiskCleanup'
    Disable-ScheduledTask -TaskName 'WinSAT' -TaskPath '\Microsoft\Windows\Maintenance'
    Disable-ScheduledTask -TaskName 'Windows Defender Cache Maintenance' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Cleanup' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Scheduled Scan' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Verification' -TaskPath '\Microsoft\Windows\Windows Defender'
}

function Edit-VisualEffectsRegistry {
    Write-Host "Adjust performance options in registry"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
}

function Install-NvidiaDriver {
    # Modified from source: https://github.com/lord-carlos/nvidia-update
    Write-Host "Installing Nvidia Driver"
    $r = Invoke-WebRequest -Uri 'https://www.nvidia.com/Download/processFind.aspx?psid=75&pfid=783&osid=74&lid=1&whql=&lang=en-us&ctk=16' -Method GET

    $version = $r.parsedhtml.GetElementsByClassName("gridItem")[2].innerText
    $url = "http://us.download.nvidia.com/Windows/Quadro_Certified/$version/$version-tesla-desktop-winserver2016-international-whql.exe"
    $driver_file = "$version-driver.exe"

    Write-Host "Downloading Nvidia M60 driver from URL + $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "$PSScriptRoot\$driver_file")

    Write-Host "Extracting Nvidia M60 driver from file $PSScriptRoot\$driver_file"
    Start-Process -FilePath "$PSScriptRoot\$driver_file" -ArgumentList "-s", "-noreboot" -Wait

    $setup_file = "C:\NVIDIA\DisplayDriver\$version\Win10_64\International\setup.exe"
    Write-Host "Installing Nvidia M60 driver from file $setup_file"
    Start-Process -FilePath $setup_file -ArgumentList "-s", "-noreboot", "-noeula" -Wait

    Write-Host "Cleaning up driver files"
    Remove-Item -Path $PSScriptRoot\$driver_file -Confirm:$false
    Remove-Item "C:\NVIDIA\DisplayDriver\$version" -Confirm:$false -Recurse
}

function Disable-Devices {
    $url = "https://gallery.technet.microsoft.com/PowerShell-Device-60d73bb0/file/147248/2/DeviceManagement.zip"
    $compressed_file = "DeviceManagement.zip"
    $extract_folder = "DeviceManagement"

    Write-Host "Downloading Device Management Powershell Script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "$PSScriptRoot\$compressed_file")

    Write-Host "Extracting Device Management Powershell Script"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$extract_folder" -Force

    Write-Host "Disabling Hyper-V Video"
    Import-Module "$PSScriptRoot\$extract_folder\DeviceManagement.psd1"
    Get-Device | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-Device -Confirm:$false
}

function Enable-Audio {
    Write-Host "Enabling Audio Service"
    Set-Service -Name "Audiosrv" -StartupType Automatic
    Start-Service Audiosrv
}

function Install-VirtualAudio {
    # TODO. CURRENTLY NOT POSSIBLE TO SILENT INSTALL. 

    # Write-Host "Downloading Virtual Audio Driver"
    # (New-Object System.Net.WebClient).DownloadFile("http://vbaudio.jcedeveloppement.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "$PSScriptRoot\$compressed_file")

    # Write-Host "Extracting Virtual Audio Driver"
    # Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$driver_folder" -Force
    
    # Write-Host "Installing Virtual Audio Driver from file $PSScriptRoot\$driver_folder\$driver_executable"
    # Start-Process -FilePath "$PSScriptRoot\$driver_folder\$driver_executable" -ArgumentList "/s", "/v`"/qn`"" "/noeula" -Wait
}

function Install-Chocolatey {
    Write-Host "Installing Chocolatey"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    chocolatey feature enable -n allowGlobalConfirmation
}

function Install-VPN {
    $url = "https://github.com/ecalder6/azure-gaming/raw/master/zerotier_cert.cer"
    $cert = "zerotier_cert.cer"

    Write-Host "Downloading zero tier certificate from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "$PSScriptRoot\$cert")

    Write-Host "Importing zero tier certificate"
    Import-Certificate -FilePath "$PSScriptRoot\$cert" -CertStoreLocation "cert:\CurrentUser\TrustedPublisher"
    Import-Certificate -FilePath "$PSScriptRoot\$cert" -CertStoreLocation "cert:\LocalMachine\TrustedPublisher"

    Write-Host "Installing ZeroTier"
    choco install zerotier-one --force
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function Join-Network {
    Write-Host "Joining network $network"
    zerotier-cli join $network
}

function Install-Steam {
    $steam_exe = "steam.exe"
    Write-Host "Downloading steam into path $PSScriptRoot\$steam_exe"
    (New-Object System.Net.WebClient).DownloadFile("https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe", "$PSScriptRoot\$steam_exe")
    Write-Host "Installing steam"
    Start-Process -FilePath "$PSScriptRoot\$steam_exe" -ArgumentList "/S" -Wait

    Write-Host "Cleaning up steam installation file"
    Remove-Item -Path $PSScriptRoot\$steam_exe -Confirm:$false
}

function Set-Steam {
    $steam = "C:\Program Files (x86)\Steam\Steam.exe"

    Write-Host "Editing registry to log into steam at startup"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Steam" -Value "$steam -login $steam_username $steam_password -silent"
}

function main {
    param (
        [string]$network,
        [string]$steam_username,
        [string]$steam_password,
        [switch]$windows_update = $false
    )

    if ($windows_update) {
        Update-Windows
    }
    Update-Firewall
    Disable-Defender
    Disable-ScheduledTasks
    Edit-VisualEffectsRegistry
    Install-NvidiaDriver
    Disable-Devices
    Enable-Audio
    Install-VirtualAudio
    Install-Chocolatey
    Install-VPN
    Join-Network
    Install-Steam
    Set-Steam
    Restart-Computer
}

main