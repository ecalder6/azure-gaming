# azure-gaming
Setup an Azure M60 VM for cloud gaming.

## About
Powershell scripts that automate the tedious process of setting up an Azure M60 VM for cloud gaming. The goal is to fully automate all
steps described in this [excellent guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html).

## Requirements
1. Sign up for an account on [zero tier](https://www.zerotier.com/) and create a network. Make sure the network is set to **public**.
Note down the network id.
2. To auto-login to steam without setup, you need to disable steam guard.
  * Alternatively, you could manually log into steam and select remember me

## Usage
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fecalder6%2Fazure-gaming%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Hot to run setup.ps1
0. Create a M60 VM on Azure
1. Remote desktop into your Azure VM instance
2. Click on the Windows key in the bottom-left corner, type "powershell", right click on Windows PowerShell app, and click on "Run as administrator".
3. Move setup.ps1 by either copy/paste from your host machine or download from https://github.com/ecalder6/azure-gaming/blob/master/setup.ps1
4. Navigate to the directory containing setup.ps1 in PowerShell and execute
```powershell
powershell -ExecutionPolicy Unrestricted -File setup.ps1 -network {zero_tier_network_id} -steam_username {your steam username} -steam_password {your_steam_password}
```

## TODO
* Automate installation of virtual audio device
