param (
    [string]$steam_username = "",
    [string]$password_file = ""
)

$steam = "C:\Program Files (x86)\Steam\Steam.exe"
$steam_password = Get-Content $password_file | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($steam_password)            
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
Write-Host "$PlainPassword"
Start-Process -FilePath $steam -ArgumentList "-login $steam_username $PlainPassword", "-silent"
