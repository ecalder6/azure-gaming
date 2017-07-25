Write-Host "Run Windows Update (from https://gallery.technet.microsoft.com/scriptcenter/Execute-Windows-Update-fc6acb16)"
# Invoke-Expression .\PS_WinUpdate.ps1

Write-Host "Enable ICMP Ping in Firewall."
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True

Write-Host "Disable Windows Defender real-time protection."
Set-MpPreference -DisableRealtimeMonitoring $true

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

Write-Host "Adjust performance options in registry"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2


Write-Host "Installing Nvidia Driver (modified version of https://github.com/lord-carlos/nvidia-update"
$r = Invoke-WebRequest -Uri 'https://www.nvidia.com/Download/processFind.aspx?psid=75&pfid=783&osid=74&lid=1&whql=&lang=en-us&ctk=16' -Method GET

$version = $r.parsedhtml.GetElementsByClassName("gridItem")[2].innerText
$url = "http://us.download.nvidia.com/Windows/Quadro_Certified/$version/$version-tesla-desktop-winserver2016-international-whql.exe"
$driver_file = ".\$version-driver.exe"

Write-Host "Downloading Nvidia M60 driver from URL + $url"
(New-Object System.Net.WebClient).DownloadFile($url, $driver_file)
