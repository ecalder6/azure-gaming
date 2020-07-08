# Cloud Gaming Made Easy

## Update 1/11/2020

1. You no longer need to use ZeroTier VPN. Steam can now stream games from outside your LAN. When deploying your VM, leave the "Network ID" field empty.
2. The VMs deployed in this guide do not support SSD. If you want SSD, use [NVv3 series](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-gpu#nvv3-series--1). If you are feeling adventurous, you can try out the new [NVv4 series](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-gpu#nvv4-series-preview--1) with [AMD MI25](https://www.amd.com/en/products/professional-graphics/instinct-mi25) and AMD EPYC 7V12(Rome). No idea if this works, but please let me know if it does :)

## About

Effortlessly stream the latest games on Azure. This project automates the set-up process for cloud gaming on a Nvidia M60 GPU on Azure.
The development of this project is heavily inspired by this [excellent guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html).

The automated setup first deploys an Azure NV6 virtual machine (VM) with a single Nvidia M60 GPU (1/2 of a M60 graphics card), configures the official Nvidia Driver Extension that installs the Nvidia driver on the VM, and finally deploys a Custom Script Extension to run the setup script. The setup script configures everything that's needed to run Steam games on the VM, such as configuring some Nvidia driver settings, setting up auto login for Windows, and eventually connecting to ZeroTier VPN.

## Disclaimer

**This software comes with no warranty of any kind**. USE AT YOUR OWN RISK! This a personal project and is NOT endorsed by Microsoft. If you encounter an issue, please submit it on GitHub.

## How Do I Stream Games?

Your Azure VM and your local machine are connected through Steam. You can stream games through this connection using [Steam Remote Play](https://support.steampowered.com/kb_article.php?ref=3629-RIAV-1617).

You can optionally use ZeroTier VPN by specifying a network ID in the deployment parameters, for other scenarios such as using a third-party streaming software.

## How Much Bandwidth Does It Take?

The bandwidth needed can vary drastically depending on your streaming host/client, game, and resolution. I recommend most people to limit their bandwidth to either 15 or 30 Mbits/sec. If you are streaming at higher than 1080P or just want to have the best possible experience, go with 50 Mbits/sec.

## Pricing

To game on the cloud on Azure, you will have to pay for the virtual machine, outgoing data bandwidth from the VM, and managed disk (See [Q & A](#q--a) for managed disk).

You can pick between 2 kinds of VM: standard and Spot. A Spot VM is around **60%** cheaper than a standard VM. The downside is that a Spot VM can be shutdown at any time. 

The calculators below are prepopulated with an estimated monthly price for playing 35 hours a month in West US 2 region. It assumes that you stream at an averge of around 30 Mbits/second (13.5 GBs an hour) and use one 128GB managed disk. You can divide the total by 35 to find the estimated cost per hour.

Azure also charges you for the number of transactions on managed disk. The calculator assumes 100k transactions a month (no idea how accurate this is).

* [Price Calculator for Standard](https://azure.com/e/5479babbd37e46b68730b27e9fd1a641)
* [Price Calculator for Spot](https://azure.com/e/f0e1298bc0984f178ba002d3316d9974)

| Type          | Bandwidth (Mbits/sec) | Monthly Data (GBs) | Monthly Price* | Hourly Price* |
| ------------- | --------------------: | -----------------: | -------------: | ------------: |
| Standard      |                    30 |                473 |         $95.11 |         $2.72 |
| Standard      |                    15 |                236 |         $74.49 |         $2.13 |
| Spot          |                    30 |                473 |         $68.16 |         $1.95 |
| Spot          |                    15 |                236 |         $47.54 |         $1.36 |

*As of 05/06/2018

## Usage

### I. Setup your local machine

1. Sign up for a [Paid Azure subscription](https://azure.microsoft.com/en-us/pricing/purchase-options/). You need a paid subscription as the free account does not grant you access to GPU VMs.
2. Have Steam ready and logged in. You can specify client streaming options in Steam's Settings > Remote Play > Advanced Client Options. Make sure to limit the bandwidth of your local steam client to 15 or 30 Mbits (50 if you don't mind the extra data cost).

You can also use Steam Link on a mobile device !

#### I.B (Optional) Setup ZeroTier VPN

For some scenarios other than Steam Remote Play

3. Sign up for an account on [zero tier VPN](https://www.zerotier.com/) and create a network. Make sure the network is set to **public**.
Note down the network id.
4.  Download and install zero tier VPN on your local machine. Join the network using the network ID noted in the previous step. **Make sure your local machine connect to the network BEFORE the VM does!**

### II. Automatically Deploy Your Azure VM

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fecalder6%2Fazure-gaming%2Fmaster%2FStandard.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

Click on the button above and fill out the form. You'll need to fill in:

* Subscription: your paid subscription
* Resource group: create a new one and name it anything you like
* Location: pick the location closest to you. Note that not every location has the VM with M60 graphics card. Check [this website](https://azure.microsoft.com/en-us/global-infrastructure/services/) for whether a region supports NV6 VM.
* Admin username and password: the login credentials for the local user.
* Vm Type: Use Standard_NV6_Promo if possible to save money. Use Standard_NV12s_v3 if you want SSD.
* Spot VM: Set to true if you want to deploy a Spot VM. Note that it is not compatible with the *Promo* series VMs
* Script location: the location of the setup script. Use the default value.
* Windows Update: whether to update windows, which takes around an hour. Recommended to leave as false.
* Network ID: network ID of your zero tier VPN, or empty if you don't need ZeroTier.

For standard VM, you could specify a time when the VM would automatically shut down and deallocate. Once it's deallocated, you do not have to pay for the VM. See [Q & A](#q--a) for more.
A list of timezones understood by Azure is available [here](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/)

**Note: your admin credentials will be stored in plain-text in the VM. See [Q & A](#q--a) for more.**

After filling these in, check on I agree the terms and click on purchase. A VM with a M60 GPU will be automatically deployed and configured for you. Note that the setup process will take around 15 minutes (1 hour + if you choose to update Windows).

You can monitor the progress of the deployment using the notification button (bell icon) on the top right. You can also check the status under Virtual Machine -> CloudGaming -> Extensions -> one of the entries in the list. If you see an error or failure, submit an issue on GitHub along with what's in detailed status.

Wait until the deployment is successful and both extensions are finished before logging in.

### III. Log into your VM

You can log into your VM using Remote Desktop Connection.

    1. Go to Virtual machines in [Azure Portal](https://portal.azure.com/) and click on CloudGaming
    2. Click on Connect and then Download RDP File (leave everything as default)
    3. Open your RDP file. Click on "Don't ask me again" and Connect for RDP popup.
    4. Enter the username and password you provided. Click on more choices -> "Use a different account" if you can't modify the username.
    5. Click on "Don't ask me again" and "Yes" for certificate verification popup.

### IV. Setup Steam

Steam is automatically installed on your VM. Launch it and log-in with your steam credentials. Once logged in, install your games through Steam on the VM. Unfortunately, Steam no longer allows interaction-free installation from local machine, requring you to do a bit of setup in the VM.

You could either install a game to your system drive (managed disk) or a temporary drive. The temporary drive has faster speeds, but you lose all your data after deallocating a VM. You will have to re-install your games every time you stop and start your VM if you choose to install on the temporary drive. See [Q & A](#q--a) for more.

If you want to stream from the Steam Link mobile app, don't forget to pair your phone and the VM from the VM's Remote Play settings !


### V. Game!

Close the remote desktop connection using the disconnect.lnk shortcut on the desktop and enjoy some cloud gaming!

If you don't use this shortcut, the VM gets locked and Steam Remote Play can not capture the game.

In Steam Remote Play, you can toggle streaming stats display with F6.

#### I Want to Manually Deploy My VM

You could manually deploy your VM through Azure portal, PowerShell, or Azure CLI. 

1. Deploy a NV6 size VM through the azure portal(see [this guide](https://lg.io/2016/10/12/cloudy-gamer-playing-overwatch-on-azures-new-monster-gpu-instances.html) for instructions). Do not forget to add the Nvidia Driver Extension to the VM !
2. Remote desktop into your Azure VM instance.

3. Launch PowerShell (click on the Windows key in the bottom-left corner, type "powershell", and click on the app PowerShell).
4. Download https://github.com/ecalder6/azure-gaming/blob/master/setup.ps1. You could download this onto your local machine and paste it through remote desktop.
5. Navigate to the directory containing setup.ps1 in PowerShell and execute

```powershell
powershell -ExecutionPolicy Unrestricted -File setup.ps1 -network {zero_tier_network_id} -admin_username {username_set_in_portal} -admin_password {password_set_in_portal} -manual_install
```

If you want to update windows, append

```powershell
-windows_update
```

6. After some time, the script will restart your VM, at which point your remote desktop session will end.
7. You can then remote desktop into your VM again a few minutes later. (1+ hour if you want to update Windows)
8. Follow [Setup Steam](#setup-steam) from above.

## Stopping a VM
After you are done with a gaming session, I recommend you stop (deallocate) the VM **using the Azure portal**. When it's stopped (deallocated), you don't have to pay for the VM. If you shut it down from Windows, you will still have to pay. Below are the steps for stopping a VM in portal:
1. Login to [Azure portal](https://portal.azure.com)
2. On the left-hand side, click on All resources
3. Click on the VM you've created (for automated, the VM name is CloudGaming).
4. Click on Stop on the top.

To start the VM, follow the steps above except that you click on start.

## Removing a VM

If you no longer wish to game on Azure, you could remove everything by:

1. Login to [Azure portal](https://portal.azure.com)
2. On the left-hand side, click on Resource Groups.
3. Click on the resource group you've created.
4. Click on delete resource group on the top.

## Updating Nvidia Driver

Go to [Install NVIDIA GPU drivers on N-series VMs running Windows](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/n-series-driver-setup#nvidia-grid-drivers) to install the latest driver. Select Nvidia GRID driver for Windows Server 2016 for the NV series VM.

## Contribution

Contributions are welcome! Please submit an issue and a PR for your change.

## Future work items

* Explore the feasibility of [image](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/capture-image-resource) and [snapshot](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/snapshot-copy-managed-disk#next-steps)
* Encrypt credentials for auto-login (achieved in [Autologon](https://docs.microsoft.com/en-us/sysinternals/downloads/autologon))

## Q & A

* What's the difference between a managed disk and a temporary drive?

    A managed disk is a persisted virtual disk drive that costs a few dollars a month. A temporary drive (called temporary storage in the VM) is an actual disk drive that sits on the computer that hosts your VM. Temporary drive is free of charge and is much faster than a managed disk. However, data on temporary drive are not persisted and will be wiped when the VM is deallocated. 

    There are 2 types of managed disk, standard and premium. Our VM type only supoorts standard disk, which has speeds similar to a typical hard drive.

* What if the game is too big for C:\? I don't want to reinstall it every time I restart the VM.

    You can create a new managed disk and attach it to your VM. See [this documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/attach-managed-disk-portal) for more.

* How secure are my credentials?

    Your admin username and password you provide in the Azure portal form will be stored as plain text in 3 instances:
    1. While the script is executing, they will be stored as plain-text in memory.
    2. To facilitate auto-login for the VM, the credentials will be stored as plain-text in registry.

    You are safe if no malicious third-party can access the memory or disk on your VM. Now since the only way to remote desktop into your VM is through the admin account, the credentials should be safe. Still, you should NOT reuse the admin username and password anywhere else.

* Do I have to pay for my VM once it's shutdown?

    It's depends on how you shut down your VM. You don't pay for the VM ONLY when it's **deallocated**. Stopping the VM through the portal or the auto-shutdown setting for standard VM should also deallocate the VM. Shutting down from Windows would not deallocate it. Still, it’s always a good idea to double check your VM status.

* Steam on my local machine does not have the option to stream from VM?
    * Make sure steam is installed and running on the VM.
    * Restart Steam on your local machine
    * If using ZeroTier Central, make sure that both your machine and the VM are connected under the members tab.
    

* Steam Remote Play closes instantly after the splash screen ? Can't stream games because the screen is locked on the VM ?

    Double click on disconnect.lnk on the VM desktop to close the remote desktop connection.

* Double clicking on disconnect.lnk does nothing?

    Right-click on disconnect.lnk and click Properties. In Target, change the "1" to "2":
    ```powershell
    C:\Windows\System32\tscon.exe 2 /dest:console
    ```

* Should I install the audio driver update for Steam?

    By default, Steam won't stream any game before you install its audio driver on the VM. Steam installs it automatically without action on your part. Alternatively, you could launch steam with "-skipstreamingdrivers".

* My Spot VM was deallocated. How do I get it back?

    To add back a Spot VM, go to your VM in Azure Portal, and press Start. There is no guarantee that the allocation will succeed.

* My question is not listed

    Submit an issue on GitHub.
