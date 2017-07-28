function Install-Steam {
    $steam_exe = "steam.exe"
    Write-Host "Downloading steam into path $PSScriptRoot\$steam_exe"
    (New-Object System.Net.WebClient).DownloadFile("https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe", "$PSScriptRoot\$steam_exe")
    Write-Host "Installing steam"
    Start-Process -FilePath "$PSScriptRoot\$steam_exe" -ArgumentList "/S" -Wait

    Write-Host "Cleaning up steam installation file"
    Remove-Item -Path $PSScriptRoot\$steam_exe -Confirm:$false
}

Install-Steam