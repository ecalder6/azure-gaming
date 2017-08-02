# Cloud Gaming Made Easy

## About
This project allows you to stream steam games through Azure cloud with only a few clicks! There is virtually no setup involved. In fact, you never have to login to the VM!
The development of this project is heavily inspired by this [excellent guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html).

The automated setup first deploys an Azure NV6 VM with an Nvidia M60 video card and configures the Custom Script Extension to run the setup script. The setup script configures everything that's needed to run steam games on the VM, such as installing the Nvidia driver, connecting to ZeroTier VPN, and setting up auto login for Windows.

## Disclaimer
**This software comes with no warranty of any kind**. USE AT YOUR OWN RISK! If you encounter an issue, please submit it on GitHub.

## Do this first
1. Sign up for an [Paid Azure subscription](https://azure.microsoft.com/en-us/pricing/purchase-options/). You need a paid subscription as the free account grants you access to GPU VMs.
2. Sign up for an account on [zero tier VPN](https://www.zerotier.com/) and create a network. Make sure the network is set to **public**.
Note down the network id.
3. Download and install zero tier VPN on your local machine. Join the network using the network ID noted in the previous step. **Make sure your local machine connect to the network BEFORE the VM does!**
3. For the one-click setup to work, you need to disable steam guard.
    * This is because you need to manually type the second-factor code into steam client, which requires you to login to the VM.
    Blizzard's phone authenticator handles this much better with ability to approve on the phone.
    * If you do not wish to disable steam guard, please follow the manual instructions provided below.

## Pricing
Use [this calculator](https://azure.microsoft.com/en-us/pricing/calculator/) to estimate your price for using Azure. Remember to pick NV6 size VM and some network bandwidth. The guide above also has an estimated price per hour. 

## How to use
### Automated
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fecalder6%2Fazure-gaming%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Click on the button above and fill out the form. You'll need to fill in:
* Subscription: your paid subscription
* Resource group: create a new one and name it anything you like
* Location: pick the location closest to you. Note that not every location has the VM with M60 graphics card. So far I've tried West US 2 and South Central US.
* Admin username and password: the login credentials for the local user.
* Script location: the location of the setup script. Use the default value.
* Windows Update: whether or not to update windows, which takes around an hour.
* Network ID: network ID of your zero tier VPN.
* Steam username and password: your steam login credentials.

**Note: your admin and steam credentials will be stored in plain-text in the VM. If you follow the manual instructions below, only your admin credentials will be stored in plain-test. See Q & A for more.**

After filling these in, check on I agree the terms and click on purchase. A VM with a M60 graphics card will be automatically deployed and configured for you. Note that the setup process will take around 15 minutes (1 hour + if you choose to update Windows). 

You can monitor the progress of the deployment using the notification button (bell icon) on the top right. You can also check the status under Virtual Machine -> CloudGaming -> Extensions -> the only entry in the list. If you see an error or failure, submit an issue on GitHub along with what's in detailed status.

After the deployment is successful, you'll need to wait for the second stage setup to finish, which should take less than 5 minutes. You will know it's ready when your local steam client allows you to install and stream games from the VM. 


### Manual
1. Deploy a NV6 size VM through the azure portal(see [this guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html) for instructions).
2. Remote desktop into your Azure VM instance.
3. Launch powershell (click on the Windows key in the bottom-left corner, type "powershell", and click on the app PowerShell).
3. Download https://github.com/ecalder6/azure-gaming/blob/master/setup.ps1. You could download this onto your local machine and paste it through remote desktop.
4. Navigate to the directory containing setup.ps1 in PowerShell and execute
```powershell
powershell -ExecutionPolicy Unrestricted -File setup.ps1 -network {zero_tier_network_id} -admin_username {username_set_in_portal} -admin_password {password_set_in_portal} -manual_install
```
If you want to update windows, append

```powershell
-windows_update
```

5. After sometime, the script will restart your VM, at which point your remote desktop session will end.
6. Wait for approximately 15 minutes and then remote desktop into your VM again.
7. Sign in to steam. Use the disconnect shortcut in C:\ to quit remote desktop.
8. Install and stream games using your local steam client.

Close the remote desktop connection using the shortcut located in C:\disconnect.lnk and enjoy some cloud gaming!

### Steam client setup
Make sure to limit the bandwidth of your local steam client to 30 MBits. You can do so through settings -> In-Home Streaming -> Advanced client options.

## Stopping a VM
After you are done with a gaming session, I recommend you stop (deallocate) the VM **using the Azure portal**. When it's stopped (deallocated), you don't have to pay for the VM. Below are the steps for stopping a VM in portal:
1. Login to [Azure portal](https://portal.azure.com)
2. On the left-hand side, click on Virtual Machines.
3. Click on the VM you've created (for automated, the VM name is CloudGaming)
4. Click on Stop on the top. 

To start the VM, follow the steps above except that you click on start.

## Removing a VM
If you no longer want to game on Azure, you could remove everything by:
1. Login to [Azure portal](https://portal.azure.com)
2. On the left-hand side, click on Virtual Machines.
3. Click on the VM you've created (for automated, the VM name is CloudGaming)
4. Click on Delete on the top. 
5. After your VM is deleted, click on Resouce Groups on the left hand side
6. Click on the resource group you've created for the VM
7. Click on Delete on the top. 

## Contribution
Contributions are welcome! Please submit an issue and a PR for your change.

## Q & A
* How secure are my credentials?

    Your admin username, admin password, steam username, and steam password you provide in the Azure form will be stored as plain text in 2 instances:
    1. While the script is executing, they will be stored as plain-text in memory.
    2. To faciliate auto-login for the VM and for steam, the credentials will be stored as plain-text in registry.
    
    Note that if you followed the manual installation instructions instead, your steam credentials will not be stored in plain-text (as they are not handled by the setup script at all).

    So you are safe as long as no malicious thrid-party is reading the VM memory during script exeuction or your registry. Now since the only way to remote desktop into your VM is through the admin account, the credentials should be pretty safe. 
    
* The deployment seems successful but my local steam client can't detect my VM?

    * Try restarting the VM. Follow the same steps as stopping your VM execept you click on restart.
    * On ZeroTier Central, make sure that both your machine and the VM are connected under the members tab.
    * Remote desktop into the VM and check if steam is installed/running.

* How do I install steam games onto the VM?

    In your steam on your computer (not the VM), you should see a drop-down arrow. Click on that and click on install on {your_vm_name}.

* Can't stream/install games because the screen is locked on the VM?

    This should only happen if you manually launched the script. Use the disconnect shortcut in C:\.

* My question is not listed

    Submit an issue on GitHub.
