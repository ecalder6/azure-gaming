param (
    [string]$network,
    [string]$steam_username,
    [string]$steam_password,
    [switch]$windows_update = $false,
    [switch]$manual_install = $false
)

function Disable-InternetExplorerESC {
    # From https://stackoverflow.com/questions/9368305/disable-ie-security-on-windows-server-via-powershell
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Update-Windows {
    $url = "https://gallery.technet.microsoft.com/scriptcenter/Execute-Windows-Update-fc6acb16/file/144365/1/PS_WinUpdate.zip"
    $compressed_file = "PS_WinUpdate.zip"
    $update_script = "PS_WinUpdate.ps1"

    Write-Host "Downloading Windows Update Powershell Script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

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

function Install-NvidiaDriver ($manual_install) {
    # Modified from source: https://github.com/lord-carlos/nvidia-update
    Write-Host "Installing Nvidia Driver"
    $version = "377.35"
    if ($manual_install) {
        $r = Invoke-WebRequest -Uri 'https://www.nvidia.com/Download/processFind.aspx?psid=75&pfid=783&osid=74&lid=1&whql=&lang=en-us&ctk=16' -Method GET
        $version = $r.parsedhtml.GetElementsByClassName("gridItem")[2].innerText
    }
    $url = "http://us.download.nvidia.com/Windows/Quadro_Certified/$version/$version-tesla-desktop-winserver2016-international-whql.exe"
    $driver_file = "$version-driver.exe"

    Write-Host "Downloading Nvidia M60 driver from URL $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "$PSScriptRoot\$driver_file")

    Write-Host "Installing Nvidia M60 driver from file $PSScriptRoot\$driver_file"
    Start-Process -FilePath "$PSScriptRoot\$driver_file" -ArgumentList "-s", "-noreboot" -Wait

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
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Host "Extracting Device Management Powershell Script"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$extract_folder" -Force

    Write-Host "Disabling Hyper-V Video"
    Import-Module "$PSScriptRoot\$extract_folder\DeviceManagement.psd1"
    Get-Device | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-Device -Confirm:$false

    Write-Host "Disabling all monitors except for Nvidia M60 monitor"
    Get-Device | Where-Object {$_.Name -Like "Generic PnP Monitor" -and $_.InstanceId -NotMatch "NVD"} | Disable-Device -Confirm:$false
}

function Enable-Audio {
    Write-Host "Enabling Audio Service"
    Set-Service -Name "Audiosrv" -StartupType Automatic
    Start-Service Audiosrv
}

function Install-VirtualAudio {
    $compressed_file = "VBCABLE_Driver_Pack43.zip"
    $driver_folder = "VBCABLE_Driver_Pack43"
    $driver_inf= "vbMmeCable64_win7.inf"

    Write-Host "Downloading Virtual Audio Driver"
    (New-Object System.Net.WebClient).DownloadFile("http://vbaudio.jcedeveloppement.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Host "Extracting Virtual Audio Driver"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$driver_folder" -Force
    
    Write-Host "Installing Virtual Audio Driver"
    pnputil.exe /add-driver "$PSScriptRoot\$driver_folder\$driver_inf" /install
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
    Import-Certificate -FilePath "$PSScriptRoot\$cert" -CertStoreLocation "cert:\LocalMachine\TrustedPublisher"

    Write-Host "Installing ZeroTier"
    choco install zerotier-one --force
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function Join-Network ($network) {
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

function Install-NSSM {
    Write-Host "Installing NSSM to auto-start steam.exe"
    choco install nssm --force
}

function Set-Steam($steam_username, $steam_password) {
    Write-Host "Start Steam as a service using nssm"
    $steam = "C:\Program Files (x86)\Steam\Steam.exe"
    $service_name = "SteamAutoStart"
    if ($steam_username.length -gt 0) {
        Write-Host "Creating a service $service_name to log into steam at startup"
        nssm install $service_name $steam "-login $steam_username $steam_password -silent"
        nssm set $service_name Start SERVICE_AUTO_START
    }
}

function Set-ScheduleWorkflow {
    $script_name = "resume.ps1"
    $url = "https://raw.githubusercontent.com/ecalder6/azure-gaming/master/$script_name"

    Write-Host "Downloading resume script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "C:\$script_name")

    Write-Host "Set up scheduled task for resume script"

    # From https://blogs.technet.microsoft.com/heyscriptingguy/2013/01/23/powershell-workflows-restarting-the-computer/
    $actionscript = '-NonInteractive -WindowStyle Normal -NoLogo -NoProfile -NoExit -Command "&''C:\resume.ps1''"'
    $pstart =  "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    Get-ScheduledTask -TaskName ResumeSetupJobTask | Unregister-ScheduledTask -Confirm:$false
    $act = New-ScheduledTaskAction -Execute $pstart -Argument $actionscript
    $trig = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName ResumeSetupJobTask -Action $act -Trigger $trig -RunLevel Highest
}

function Add-DisconnectShortcut {
    # From https://stackoverflow.com/questions/9701840/how-to-create-a-shortcut-using-powershell
    Write-Host "Create disconnect shortcut under C:\disconnect.lnk"
    $username = $env:USERNAME
    $session = ((quser /server:$server | Where-Object { $_ -match $username }) -split ' +')[2]

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\disconnect.lnk")
    $Shortcut.TargetPath = "C:\Windows\System32\tscon.exe"
    $Shortcut.Arguments = "$session /dest:console"
    $Shortcut.Save()
}

function Add-UnlockVMService {
    # $service_name = "UnlockVM"
    # $shortcut = "C:\disconnect.lnk"

    # Write-Host "Creating a service $service_name to unlock screen"
    # nssm install $service_name $shortcut
    # nssm set $service_name Start SERVICE_AUTO_START

    $script_name = "unlock.ps1"
    $url = "https://raw.githubusercontent.com/ecalder6/azure-gaming/master/$script_name"

    Write-Host "Downloading unlock script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "C:\$script_name")

    Write-Host "Set up scheduled task for unlock script"

    # From https://blogs.technet.microsoft.com/heyscriptingguy/2013/01/23/powershell-workflows-restarting-the-computer/
    $actionscript = '-NonInteractive -WindowStyle Normal -NoLogo -NoProfile -NoExit -Command "&''C:\unlock.ps1''"'
    $pstart =  "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    Get-ScheduledTask -TaskName UnlockScreenJobTask | Unregister-ScheduledTask -Confirm:$false
    $act = New-ScheduledTaskAction -Execute $pstart -Argument $actionscript
    $trig = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName UnlockScreenJobTask -Action $act -Trigger $trig -RunLevel Highest
}

function Add-DummyUser {
    $registry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $username = "DummyUser"
    $password = ConvertTo-SecureString "P@ssW0rD!" -AsPlainText -Force

    Write-Host "Creating a dummy user and set it to login at startup"
    New-LocalUser -Name $username -Password $password -Description "Dummy account used to launch games."
    Add-LocalGroupMember -Group Administrators -Member $username
    Set-ItemProperty $registry "AutoAdminLogon" -Value "1" -type String
    Set-ItemProperty $registry "DefaultDomainName" -Value "$env:computername" -type String
    Set-ItemProperty $registry "DefaultUsername" -Value $username -type String
    Set-ItemProperty $registry "DefaultPassword" -Value $password -type String
}

function Add-UnlockVM {
    $shortcut = "C:\disconnect.lnk"
    
    Write-Host "Editing registry to unlock VM at startup"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "UnlockVM" -Value $shortcut
}

workflow Set-Computer($network, $steam_username, $steam_password, $manual_install, $windows_update) {
    if ($windows_update) {
        Update-Windows
    }
    Update-Firewall
    Disable-Defender
    Disable-ScheduledTasks
    Install-NvidiaDriver $manual_install
    Install-Chocolatey
    Install-VPN
    Join-Network $network
    Install-NSSM
    Add-DisconnectShortcut
    Add-DummyUser

    Set-ScheduleWorkflow
    Restart-Computer -Wait

    # Should now be logged in as dummy user
    Disable-Devices
    Disable-InternetExplorerESC
    Edit-VisualEffectsRegistry
    Enable-Audio
    # Install-VirtualAudio
    Add-UnlockVM
    Install-Steam
    Set-Steam $steam_username $steam_password

    Restart-Computer
}

Set-Computer $network $steam_username $steam_password $manual_install $windows_update -JobName SetComputer