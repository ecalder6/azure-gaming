#!/bin/bash


# set of commands to manage azure VM resources as part of a cloud gaming instance

# CONSTANTS. SET THIS TO YOUR PARAMETERS
. ./params.conf

# functions

case "$1" in
    token )
	# update conf file to have new azg_token
	AZG_TOKEN=$(curl -X POST -d "grant_type=client_credentials&client_id=$APP_ID&client_secret=$PASSWORD&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/$TENANT_ID/oauth2/token | jq ".access_token" -r) 

	sed -i -e "s/AZG_TOKEN=.*/AZG_TOKEN=$AZG_TOKEN/" ./params.conf

	echo "Updated AZG_TOKEN in ./params.conf"
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
	# get IP address
	ipaddress=$(curl -X GET -H "Authorization: Bearer $AZG_TOKEN" -H "Content-Type:application/json" -H "Accept:application/json" https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RSG/providers/Microsoft.Network/publicIpAddresses\?api-version\=2019-12-01 | jq .value[0].properties.ipAddress -r)

	echo "Launching remmina for $NAME: $ipaddress"

	# create remmina file for RDP
	sed -e "s/full address:s:.*/full address:s:$ipaddress/" azurevm.rdp > today.rdp
	remmina -c today.rdp 
	#need to save the remmeida file with a custom resolution, otherwise segfault
	;;
    
    parsec )
	# launch parsec - this is trivial
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

