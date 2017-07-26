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
There are 2 flavors of the setup scripts, setup.ps1 and setup_auto.ps1

setup.ps1 is meant to be executed by the user on the VM, and setup_auto.ps1 is meant to be executed at deployment without user interaction.

### Hot to run setup.ps1
0. Create a M60 VM on Azure
1. Remote desktop into your Azure VM instance
2. Click on the Windows key in the bottom-left corner, type "powershell", right click on Windows PowerShell app, and click on "Run as administrator".
3. Move setup.ps1 by either copy/paste from your host machine or download from https://github.com/ecalder6/azure-gaming/blob/master/setup.ps1
4. Navigate to the directory containing setup.ps1 in PowerShell and execute
```powershell
powershell -ExecutionPolicy Unrestricted -File setup.ps1 -network {zero_tier_network_id} -steam_username {your steam username} -steam_password {your_steam_password}
```

### Hot to run setup_auto.ps1
0. Create a M60 VM on Azure with **Custom Script Extension**
1. Upload setup_auto.ps1 from this repo and run it using Custom Script Extension.

## TODO
* Automate disabling Hyper-V video after restart
* Automate installation of virtual audio device
