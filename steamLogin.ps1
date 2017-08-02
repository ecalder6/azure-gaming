param (
    [string]$steam_username = "",
    [string]$password_file = ""
)


$steam = "C:\Program Files (x86)\Steam\Steam.exe"
$steam_password = Get-Content $password_file | ConvertTo-SecureString
Start-Process -FilePath $steam -ArgumentList "-login $steam_username $steam_password", "-silent" -Wait
