# Game on the cloud in Azure with one-click

## About
This project allows you to stream steam games through Azure cloud with only a single click! There is virtually no setup involved. In fact, you never have to login to the VM!
The development of this project is heavily inspired by this [excellent guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html).

## Disclaimer
**This software comes with no warranty of any kind**. USE AT YOUR OWN RISK! If you encounter an issue, please submit it on GitHub.

## Do this first
1. Sign up for an [Paid Azure subscription](https://azure.microsoft.com/en-us/pricing/purchase-options/). You need a paid subscription as I don't think the free account grants you access to GPU VMs.
2. Sign up for an account on [zero tier VPN](https://www.zerotier.com/) and create a network. Make sure the network is set to **public**.
Note down the network id.
3. Download and install zero tier VPN on your local machine. Join the network using the network ID noted in the previous step.
3. For the one-click setup to work, you need to disable steam guard.
    * This is because you need to manually type the second-factor code into steam client, which requires you to login to the VM.
    Blizzard's phone authenticator handles this much better with ability to approve on the phone.
    * If you do not wish to disable steam guard, please follow the manual instructions provided below.

## Pricing
Use [this calculator](https://azure.microsoft.com/en-us/pricing/calculator/) to estimate your price. Remember to pick NV6 size VM and some network bandwidth.

## How to use
### Automated
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fecalder6%2Fazure-gaming%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Just click on the button above and fill out the form! A VM will be automatically deployed and configured for you. Note that the setup process will take around 15 minutes. You will know it's ready when your local steam client allows you to install and stream games from the VM.

### Manual
1. Deploy a NV6 size VM through the azure portal(see [this guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html) for instructions).
2. Remote desktop into your Azure VM instance.
3. Launch powershell (click on the Windows key in the bottom-left corner, type "powershell", and click on the app PowerShell).
3. Download https://github.com/ecalder6/azure-gaming/blob/master/setup.ps1. You could download this onto your local machine and paste it through remote desktop.
4. Navigate to the directory containing setup.ps1 in PowerShell and execute
```powershell
powershell -ExecutionPolicy Unrestricted -File setup.ps1 -network {zero_tier_network_id} -manual_install
```
5. After sometime, the script will restart your VM, at which point your remote desktop session will end.
6. Wait for approximately 15 minutes and then remote desktop into your VM again.
7. Sign in to steam. Use the disconnect shortcut in C:\ to quit remote desktop.
8. Install and stream games using your local steam client.

Close the remote desktop connection using the shortcut located in C:\disconnect.lnk and enjoy some cloud gaming!

### Steam client setup
Make sure to limit the bandwidth of your local steam client to 30 MBits. You can do so through settings -> In-Home Streaming -> Advanced client options.

## Contribution
Contributions are welcome! Please submit an issue and a PR for your change.

## Q & A
* How secure are my credentials?

    Your admin username, admin password, steam username, and steam password you provide in the Azure form will be stored as plain text in 2 instances:
    1. While the script is executing, they will be stored as plain-text in memory.
    2. To faciliate auto-login for the VM and for steam, the credentials will be stored as plain-text in registry.

    So you are safe as long as no malicious thrid-party is reading the VM memory during script exeuction or your registry. Now since the only way to
    remote desktop into your VM is through the admin account, the credentials should be pretty safe. 

* How do I install steam games onto the VM?

    In your steam on your computer (not the VM), you should see a drop-down arrow. Click on that and click on install on {your_vm_name}.

* Can't stream/install games because the screen is locked on the VM?

    This should only happen if you manually launched the script. Use the disconnect shortcut in C:\.

* Why is Windows update included in the script but not used?

    You can trigger the update with the following command
    ```powershell
    powershell -ExecutionPolicy Unrestricted -File setup.ps1 -windows_update
    ```
    It's not used as the update takes a long time to complete. You could also easily update windows yourself by opening Update & Security in Settings.

* Why do I still need to remote desktop into the VM with automatic script execution?
    1. It's not possible to silently install VB-CABLE due to their use of a custom exe installer.
    2. Steam won't start unless a user logs in (not sure why).

* My question is not listed

    Submit an issue on GitHub.
