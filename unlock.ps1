$username = $env:USERNAME
$session = ((quser /server:$server | Where-Object { $_ -match $username }) -split ' +')[2]
& "$session /dest:console"