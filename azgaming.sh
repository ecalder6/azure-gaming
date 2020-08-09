#!/bin/bash


# set of commands to manage azure VM resources as part of a cloud gaming instance
PARAMFILE=/home/$USER/.azgaming.params
RDPTEMPLATE=template.rdp
RDPTODAY=today.rdp
PARAMTEMPLATE=./template.params


# CONSTANTS. SET THIS TO YOUR PARAMETERS
. $PARAMFILE


# functions
case "$1" in
    init )	
	if [[ -e $PARAMFILE ]]
	then
	    echo "moving $PARAMFILE to $PARAMFILE.old"
	    mv $PARAMFILE $PARAMFILE.old
	fi
	echo "Copying $SOURCE to $PARAMFILE"
	cp $PARAMTEMPLATE $PARAMFILE

	echo "Setting parameters"
	echo "Please login into Azure Cloud Shell (https://shell.azure.com/) for this info"
	echo ""
	echo "First, the subcription and tenant ids. You can get this info from:"
	echo "  az account list"
	echo "and the 'id' and 'tenantId' fields in the returned json"
	echo ""
	read -p "Subscription id (id): " SUB_ID
	read -p "Tenant Id (tenantId): " TENANT_ID

	sed -i -e "s/SUB_ID=.*/SUB_ID=$SUB_ID/" $PARAMFILE
	sed -i -e "s/TENANT_ID=.*/TENANT_ID=$TENANT_ID/" $PARAMFILE

	echo ""
	echo "Next, we'll register an 'app' to use for the API going forward"
	echo ""
	echo "To register a new API use:"
	echo "  az ad sp create-for-rbac --name MYAWESOMENAME"
	echo "(to be fair, name could be skipped at Azure will create one for you)"
	echo ""

	read -p "Application ID (appID): " APP_ID
	read -p "Application Secret (password): " SECRET


	sed -i -e "s/SUB_ID=.*/SUB_ID=$SUB_ID/" $PARAMFILE
	sed -i -e "s/TENANT_ID=.*/TENANT_ID=$TENANT_ID/" $PARAMFILE

	echo ""
	echo "Lastly, we'll set the resource group and computer name"
	echo "This may have already been done from the main site"
	echo "Or we can register a new machine now"
	echo ""

	echo "To list your current machine and thier resource group"
	echo "  az vm list -o table"
	echo ""
	echo "To list your current resource groups use"
	echo "  az group list"
	echo "To create a new resource group use"
	echo "  az group create -l LOCATION -g GROUP_NAME"
	echo ""
	read -p "Resource Group Name (name): " RSG
	echo ""

	sed -i -e "s/RSG=.*/RSG=$RSG/" $PARAMFILE

	;;
	
    token )
	# check for jq
	if ! command -v jq &> /dev/null
	then
	    echo "'jq' (a lightweight JSON parser, https://stedolan.github.io/jq/)"
	    echo "was not found. This program is needed to parse the token from azure."
	    echo "Please install using:"
	    echo "  sudo apt-get update"
	    echo "  sudo apt-get install jq"

	    # use this instead of exit or return to protect against either
	    # source or execution of script
	    kill -SIGINT $$
	fi

	
	# update conf file to have new azg_token
	AZG_TOKEN=$(curl -X POST -d "grant_type=client_credentials&client_id=$APP_ID&client_secret=$SECRET&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/$TENANT_ID/oauth2/token | jq ".access_token" -r) 

	sed -i -e "s/AZG_TOKEN=.*/AZG_TOKEN=$AZG_TOKEN/" $PARAMFILE

	echo "Updated AZG_TOKEN in $PARAMFILE"
	;;
    
    start )
	# start
	curl -X POST -d "" -H "Authorization: Bearer $AZG_TOKEN" $AZURE_SITE/$SUB_ID/resourceGroups/$RSG/providers/Microsoft.Compute/virtualMachines/$NAME/start\?api-version\=2019-12-01
	echo "Starting VM $NAME"
	;;

    status )	
	# check status
	curl -X GET -H "Authorization: Bearer $AZG_TOKEN" -H "Content-Type:application/json" -H "Accept:application/json" https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RSG/providers/Microsoft.Compute/virtualMachines/$NAME\?api-version\=2019-12-01\&\$expand\=instanceView | jq .properties.instanceView.statuses
	;;

    rdp )
	# check for remmina
	if ! command -v remmina &> /dev/null
	then
	    echo "'remmina' (a RDP client, https://remmina.org/) was not found. "
	    echo "This enables log in to the Azure VM so the parsec server launches."
	    echo "Please install using (https://remmina.org/how-to-install-remmina/):"
	    echo "  sudo apt install dirmngr"
 	    echo "  sudo apt-key adv --fetch-keys https://www.remmina.org/raspbian/remmina_raspbian.asc"
	    echo "  sudo bash -c 'echo \"deb https://www.remmina.org/raspbian/ buster main\" > /etc/apt/sources.list.d/remmina_raspbian.list'"
	    echo "  sudo apt update"
	    echo "  sudo apt install remmina" 
	    echo ""
	    echo "To save the username and password of your VM use gnome-keyring:"
	    echo "  sudo apt install gnome-keyring"
	    echo ""
	    # use this instead of exit or return to protect against either
	    # source or execution of script
	    kill -SIGINT $$
	fi

	if [ ! -e $RDPTEMPLATE ]
	then
	    echo "Please use remmina to save as a rdp configuration to template.rdp"
	    echo "1. Start remmina using 'remmina'"
	    echo "2. Create a new connection profile using button in top left"
	    echo "3. Set 'Name' to something unique like MyAzureVM"
	    echo "4. Leave 'Server' empty."
	    echo "5. Set 'user name' and 'user password' to your VM's credentials"
	    echo "6. Set 'Domain' to 'MicrosoftAccount'"
	    echo "7. Specify 'use initial window size' or custom resolution (remmina tends to "
	    echo "   segfault if resolution is 'use client')"
	    echo "8. Click 'Save'"
	    echo "9. Select your newly created configuration in the main page"
	    echo "10. In the 3-bar menu at top right select 'Export'"
	    echo "11. Save as 'template.rdp' in the azure-gaming directory"
	    echo ""
	    echo "When launching remmina with azgaming.sh rdp the template.rdp file will be "
	    echo "copied to today.rdp with today's IP address added"
	    echo ""
	    kill -SIGINT $$
	fi	    
	
	
	# get IP address
       ipaddress=$(curl -X GET -H "Authorization: Bearer $AZG_TOKEN" -H "Content-Type:application/json" -H "Accept:application/json" https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RSG/providers/Microsoft.Network/publicIpAddresses\?api-version\=2019-12-01 | jq .value[0].properties.ipAddress -r)

	echo "Launching remmina for $NAME: $ipaddress"

	# create remmina file for RDP
	sed -e "s/full address:s:.*/full address:s:$ipaddress/" $RDPTEMPLATE > $RDPTODAY
	remmina -c $RDPTODAY
	#need to save the remmeida file with a custom resolution, otherwise segfault
	;;
    
    parsec )
	# launch parsec - this is trivial
	# check for parsec
	if ! command -v parsecd &> /dev/null
	then
	    echo "'parsecd' (the gaming streaming software, https://parsecgaming)"
	    echo "was not found. This program is needed to stream the game from azure."
	    echo "Please install using (or their webpage):"
	    echo "  sudo apt-get update"
	    echo "  sudo apt-get install parsec"

	    # use this instead of exit or return to protect against either
	    # source or execution of script
	    kill -SIGINT $$
	fi

	parsecd
	;;
    
    info )
	# get suplimental info
	curl -X GET -H "Authorization: Bearer $AZG_TOKEN" -H "Content-Type:application/json" -H "Accept:application/json" https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RSG/providers/Microsoft.Compute/virtualMachines\?api-version\=2019-12-01
	;;
    
    stop )
	# deallocate (stop getting charged) the machine 
	curl -X POST -d "" -H "Authorization: Bearer $AZG_TOKEN" https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RSG/providers/Microsoft.Compute/virtualMachines/$NAME/deallocate\?api-version\=2019-12-01

	echo "Stopping $NAME"
	;;
    
    *)
	echo "Usage: azgaming.sh token/start/status/rdp/parsec/stop/info"
	echo ""
	echo "token - Aquire API token for use and store in params.conf"
	echo "start - Start your gaming VM"
	echo "status - Get status of VM (stopping/starting/running/etc)"
	echo "rdp - Login to your RDP using remmina. Needed to start parsec"
	echo "parsec - Launch parsec"
	echo "stop - Stop and Deallocate your VM. MUST BE DONE TO END USAGE COST"
	echo "info - Additional information about your VM"
	echo ""
	;;
esac

