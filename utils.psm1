[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$webClient = new-object System.Net.WebClient
$webClient.Headers.Add("user-agent", "Mozilla/5.0 (Android 4.4; Mobile; rv:41.0) Gecko/41.0 Firefox/41.0")
function Disable-InternetExplorerESC {
    # From https://stackoverflow.com/questions/9368305/disable-ie-security-on-windows-server-via-powershell
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Output "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Download-File($displayName, $description, $url, $output) {
    Import-Module BitsTransfer
    Start-BitsTransfer -Source $url -Destination $output -DisplayName $displayName -Description $description
}


function Install-Rainway {
    if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $rainwayRelease = Invoke-WebRequest 'https://releases.rainway.io/Installer_current.json' | ConvertFrom-Json
        if (!$rainwayRelease) {
            Write-Host "Failed to fetch remote Rainway config" -ForegroundColor Red
            return
        }
        $version = $rainwayRelease.Version
        $url = "https://releases.rainway.io/Installer_$version.exe"
        $downloadedFile = "$PSScriptRoot\RainwayInstaller.exe"

        $description = "Rainway is a web based game streaming platform that lets you play your favorite PC games anywhere. Learn more at rainway.io"
        Download-File  -displayName  "Downloading Rainway ($version)" -description $description -url $url -output $downloadedFile
     

        Unblock-File -Path $downloadedFile

        Write-Output "Installing Rainway ($version) from file $downloadedFile"
        Start-Process -FilePath $downloadedFile -ArgumentList "/qn" -Wait

        Write-Output "Cleaning up Rainway installation file"
        Remove-Item -Path $downloadedFile -Confirm:$false
    }
    else {
        Write-Host "You must be running as administrator to install Rainway." -ForegroundColor Red 
    }
}

function Update-Windows {
    $url = "https://gallery.technet.microsoft.com/scriptcenter/Execute-Windows-Update-fc6acb16/file/144365/1/PS_WinUpdate.zip"
    $compressed_file = "PS_WinUpdate.zip"
    $update_script = "PS_WinUpdate.ps1"

    Write-Output "Downloading Windows Update Powershell Script from $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Output "Extracting Windows Update Powershell Script"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\" -Force

    Write-Output "Running Windows Update"
    Invoke-Expression $PSScriptRoot\$update_script
}

function Update-Firewall {
    Write-Output "Enable ICMP Ping in Firewall."
    Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True
}

function Disable-Defender {
    Write-Output "Disable Windows Defender real-time protection."
    Set-MpPreference -DisableRealtimeMonitoring $true
}

function Disable-ScheduledTasks {
    Write-Output "Disable unnecessary scheduled tasks"
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
    Write-Output "Adjust performance options in registry"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
}

function Install-NvidiaDriver ($manual_install) {
    # Modified from source: https://github.com/lord-carlos/nvidia-update
    Write-Output "Installing Nvidia Driver"
    $url = "https://go.microsoft.com/fwlink/?linkid=836843"
    $driver_file = "nvidia-driver.exe"

    Write-Output "Downloading Nvidia M60 driver from URL $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$driver_file")

    Write-Output "Installing Nvidia M60 driver from file $PSScriptRoot\$driver_file"
    Start-Process -FilePath "$PSScriptRoot\$driver_file" -ArgumentList "-s", "-noreboot" -Wait
}

function Disable-Devices {
    $url = "https://gallery.technet.microsoft.com/PowerShell-Device-60d73bb0/file/147248/2/DeviceManagement.zip"
    $compressed_file = "DeviceManagement.zip"
    $extract_folder = "DeviceManagement"

    Write-Output "Downloading Device Management Powershell Script from $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Output "Extracting Device Management Powershell Script"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$extract_folder" -Force

    Write-Output "Disabling Hyper-V Video"
    Import-Module "$PSScriptRoot\$extract_folder\DeviceManagement.psd1"
    Get-Device | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-Device -Confirm:$false
}

function Enable-Audio {
    Write-Output "Enabling Audio Service"
    Set-Service -Name "Audiosrv" -StartupType Automatic
    Start-Service Audiosrv
}

function Install-VirtualAudio {
    $compressed_file = "VBCABLE_Driver_Pack43.zip"
    $driver_folder = "VBCABLE_Driver_Pack43"
    $driver_inf = "vbMmeCable64_win7.inf"
    $hardward_id = "VBAudioVACWDM"

    Write-Output "Downloading Virtual Audio Driver"
    $webClient.DownloadFile("http://vbaudio.jcedeveloppement.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Output "Extracting Virtual Audio Driver"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$driver_folder" -Force

    $wdk_installer = "wdksetup.exe"
    $devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\x64\devcon.exe"

    Write-Output "Downloading Windows Development Kit installer"
    $webClient.DownloadFile("http://go.microsoft.com/fwlink/p/?LinkId=526733", "$PSScriptRoot\$wdk_installer")

    Write-Output "Downloading and installing Windows Development Kit"
    Start-Process -FilePath "$PSScriptRoot\$wdk_installer" -ArgumentList "/S" -Wait

    $cert = "vb_cert.cer"
    $url = "https://github.com/ecalder6/azure-gaming/raw/master/$cert"

    Write-Output "Downloading vb certificate from $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$cert")

    Write-Output "Importing vb certificate"
    Import-Certificate -FilePath "$PSScriptRoot\$cert" -CertStoreLocation "cert:\LocalMachine\TrustedPublisher"

    Write-Output "Installing virtual audio driver"
    Start-Process -FilePath $devcon -ArgumentList "install", "$PSScriptRoot\$driver_folder\$driver_inf", $hardward_id -Wait
}

function Install-Chocolatey {
    Write-Output "Installing Chocolatey"
    Invoke-Expression ($webClient.DownloadString('https://chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    chocolatey feature enable -n allowGlobalConfirmation
}

function Disable-IPv6To4 {
    Set-Net6to4Configuration -State disabled
    Set-NetTeredoConfiguration -Type disabled
    Set-NetIsatapConfiguration -State disabled
}

function Install-VPN {
    $cert = "zerotier_cert.cer"
    $url = "https://github.com/ecalder6/azure-gaming/raw/master/$cert"

    Write-Output "Downloading zero tier certificate from $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$cert")

    Write-Output "Importing zero tier certificate"
    Import-Certificate -FilePath "$PSScriptRoot\$cert" -CertStoreLocation "cert:\LocalMachine\TrustedPublisher"

    Write-Output "Installing ZeroTier"
    choco install zerotier-one --force
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}

function Join-Network ($network) {
    Write-Output "Joining network $network"
    zerotier-cli join $network
}

function Install-NSSM {
    Write-Output "Installing NSSM for launching services that run apps at startup"
    choco install nssm --force
}

function Install-Steam {
    $steam_exe = "steam.exe"
    Write-Output "Downloading steam into path $PSScriptRoot\$steam_exe"
    $webClient.DownloadFile("https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe", "$PSScriptRoot\$steam_exe")
    Write-Output "Installing steam"
    Start-Process -FilePath "$PSScriptRoot\$steam_exe" -ArgumentList "/S" -Wait

    Write-Output "Cleaning up steam installation file"
    Remove-Item -Path $PSScriptRoot\$steam_exe -Confirm:$false
}

function Set-ScheduleWorkflow ($admin_username, $admin_password, $manual_install) {
    $script_name = "setup2.ps1"
    $url = "https://raw.githubusercontent.com/ecalder6/azure-gaming/master/$script_name"

    Write-Output "Downloading second stage setup script from $url"
    $webClient.DownloadFile($url, "C:\$script_name")

    $powershell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $service_name = "SetupSecondStage"
    Write-Output "Creating a service $service_name to finish setting up"
    $cmd = "-ExecutionPolicy Unrestricted -NoProfile -File C:\$script_name -admin_username `"$admin_username`" -admin_password `"$admin_password`""
    if ($manual_install) {
        $cmd = -join ($cmd, " -manual_install")
    }

    nssm install $service_name $powershell $cmd
    nssm set $service_name Start SERVICE_AUTO_START
    nssm set $service_name AppExit 0 Exit
}

function Disable-ScheduleWorkflow {
    $service_name = "SetupSecondStage"
    nssm remove $service_name confirm
}

function Add-DisconnectShortcut {
    # From https://stackoverflow.com/questions/9701840/how-to-create-a-shortcut-using-powershell
    Write-Output "Create disconnect shortcut under C:\disconnect.lnk"

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\disconnect.lnk")
    $Shortcut.TargetPath = "C:\Windows\System32\tscon.exe"
    $Shortcut.Arguments = "1 /dest:console"
    $Shortcut.Save()
}

function Add-AutoLogin ($admin_username, $admin_password) {
    Write-Output "Make the password and account of admin user never expire."
    Set-LocalUser -Name $admin_username -PasswordNeverExpires $true -AccountNeverExpires

    Write-Output "Make the admin login at startup."
    $registry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty $registry "AutoAdminLogon" -Value "1" -type String
    Set-ItemProperty $registry "DefaultDomainName" -Value "$env:computername" -type String
    Set-ItemProperty $registry "DefaultUsername" -Value $admin_username -type String
    Set-ItemProperty $registry "DefaultPassword" -Value $admin_password -type String
}
