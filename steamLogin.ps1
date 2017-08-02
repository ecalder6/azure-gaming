param (
    [string]$steam_username = "",
    [string]$password_file = ""
)
$ps_exec = "C:\PSTools\PsExec.exe"
$steam = "C:\Program Files (x86)\Steam\Steam.exe"
$steam_password = Get-Content $password_file | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($steam_password)            
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
Set-Content "C:\test" $PlainPassword
Start-Process -FilePath $ps_exec -ArgumentList "-d", "cmd", '"'$steam' -login '$steam_username' '$PlainPassword' -silent" "'
