$username = $env:USERNAME
$session = ((quser /server:$server | Where-Object { $_ -match $username }) -split ' +')[2]
C:\Windows\System32\tscon.exe $session /dest:console