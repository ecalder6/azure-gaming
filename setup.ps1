
function Update-Windows {
    # Source: https://gallery.technet.microsoft.com/scriptcenter/Execute-Windows-Update-fc6acb16
    Write-Host "Running Windows Update"
    Invoke-Expression .\PS_WinUpdate.ps1
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
    $driver_file = ".\$version-driver.exe"

    Write-Host "Downloading Nvidia M60 driver from URL + $url"
    (New-Object System.Net.WebClient).DownloadFile($url, $driver_file)

    Write-Host "Extracting Nvidia M60 driver from file $driver_file"
    # Start-Process -FilePath ".\$driver_file" -ArgumentList "-s", "-noreboot" -Wait

    $setup_file = "C:\NVIDIA\DisplayDriver\$version\Win10_64\International\setup.exe"
    Write-Host "Installing Nvidia M60 driver from file $setup_file"
    # Start-Process -FilePath $setup_file -ArgumentList "-s", "-noreboot", "-noeula" -Wait

    Write-Host "Cleaning up driver files"
    Remove-Item -Path $driver_file -Confirm:$false
    Remove-Item "C:\NVIDIA\DisplayDriver\$version\*" -Confirm:$false -Recurse
}

function Disable-Devices {
    # Source: https://gallery.technet.microsoft.com/PowerShell-Device-60d73bb0
    Write-Host "Disabling Hyper-V Video"
    Import-Module .\DeviceManagement\DeviceManagement.psd1
    Get-Device | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-Device -Confirm:$false
}

function main {
    # TODO: UNCOMMENT commands

    Update-Windows
    Update-Firewall
    Disable-Defender
    Disable-ScheduledTasks
    Edit-VisualEffectsRegistry
    Install-NvidiaDriver
    Disable-Devices
}

main