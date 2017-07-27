# azure-gaming
Setup an Azure M60 Virtual Machine (VM) for cloud gaming.

## About
Powershell scripts that automate the tedious process of setting up an Azure M60 VM for cloud gaming. The goal is to fully automate all
steps described in this [excellent guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html).

## Disclaimer
There is no gaurantee that the script or the deployment will work. Please submit any issues you see on GitHub. PRs are also welcome!

## Requirements
1. Sign up for an [Paid Azure subscription](https://azure.microsoft.com/en-us/pricing/purchase-options/). You need a paid subscription as I don't think the free account grants you access to GPU VMs.
2. Sign up for an account on [zero tier](https://www.zerotier.com/) and create a network. Make sure the network is set to **public**.
Note down the network id.
3. To auto-login to steam without manual interaction, you need to disable steam guard.
  * This is because you need to manually type the second-factor code into steam client. Blizzard's phone authenticator handles this much better with ability to approve on the phone.
  * Alternatively, you could manually log into steam and select remember me.

## Usage
### Deploy an Azure M60 VM
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fecalder6%2Fazure-gaming%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

You could click the button above to automate most of the deployment or manually deploy through the azure portal(see [this guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html) for instructions). If you are manually deploying and want to run the script automatically, configure Custom Script Extension (see section below).

Complete the form, check "I agree" for terms, and click on purchase. If you don't disable steam guard, leave steam username and password blank and manually login later.

### Run setup.ps1
The setup powershell script can either be run manually or automatically through the use of Custom Script Extension
#### Automatic
0. If you use the deploy to azure button, you can skip this section.
1. In Step 3 of create VM, "Configure optional features", click on Extensions.
2. Click on Add extension, Custom Script Extension, and Create.
3. In script file field, update setup.ps1.
4. In Arguments, write "network {zero_tier_network_id} -steam_username {your steam username} -steam_password {your_steam_password}". Leave the steam login info blank if you don't disable steam guard.
5. Click on OK and create the VM as per instruction in the above guide.

#### Manual
1. Remote desktop into your Azure VM instance
2. Click on the Windows key in the bottom-left corner, type "powershell", and click on the app PowerShell.
3. Move setup.ps1 by either copy/paste from your host machine or download from https://github.com/ecalder6/azure-gaming/blob/master/setup.ps1
4. Navigate to the directory containing setup.ps1 in PowerShell and execute
```powershell
powershell -ExecutionPolicy Unrestricted -File setup.ps1 -network {zero_tier_network_id} -steam_username {your steam username} -steam_password {your_steam_password} -manual_install
```

### Finish up
After either automatic or manual script execution, a restart will happen. 
You then need to remote desktop into the VM. You will see a PowerShell window pop up as soon as you login. Let it run and the window for installing VB-CABLE will show up.
Click on install, trust publisher, and close the IE window it opens after installation. The PowerShell window should report success soon afterwards. Log into steam now if it's not already logged in.
Manually restart after steam has finished updating. After that, you should be all set!

Close the remote desktop connection using the shortcut located in C:\disconnect.lnk and enjoy some cloud gaming!


## Q & A
* How do I install steam games onto the VM?
In your steam on your computer (not the VM), you should see a drop-down arrow. Click on that and click on install on {your_vm_name}.

* Why is Windows update included in the script but not used?
You can trigger the update with the following command
```powershell
powershell -ExecutionPolicy Unrestricted -File setup.ps1 -windows_update
```

I didn't include it as it takes a long time to update. You could also easily update windows yourself by opening Update & Security in Settings.

* Why do I still need to remote desktop into the VM with automatic script execution?
1. It's not possible to silently install VB-CABLE due to their use of a custom exe installer.
2. Steam won't start unless a user logs in (not sure why).
