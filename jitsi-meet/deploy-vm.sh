#!/bin/bash

# Function to show a progress bar
function show_progress {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    local temp
    echo -n "Creating VM... "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo "Done!"
}

# Uncomment the following lines to delete the existing resource group
echo "Deleting existing resource group..."
az group delete --name deployment-test --yes --no-wait

# Wait for the deletion to complete with a timeout
echo "Waiting for the resource group to be deleted..."
end=$((SECONDS+300)) # 5 minutes timeout
while [ $SECONDS -lt $end ]; do
    rg_exists=$(az group exists --name deployment-test)
    if [ "$rg_exists" = "false" ]; then
        echo "Resource group 'deployment-test' successfully deleted."
        break
    else
        echo "Resource group 'deployment-test' still exists. Waiting for deletion to complete..."
        sleep 10
    fi
done

if [ "$rg_exists" = "true" ]; then
    echo "Failed to delete the resource group 'deployment-test' within the timeout period."
    exit 1
fi

# Create resource group
az group create --name deployment-test --location eastus

# Create network security group
az network nsg create --resource-group deployment-test --name myNetworkSecurityGroup

# Create NSG rules
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-ssh --priority 1000 --protocol Tcp --destination-port-range 22 --access Allow
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-http --priority 1010 --protocol Tcp --destination-port-range 80 --access Allow
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-https --priority 1020 --protocol Tcp --destination-port-range 443 --access Allow
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-10000-udp --priority 1030 --protocol Udp --destination-port-range 10000 --access Allow
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-3478-udp --priority 1040 --protocol Udp --destination-port-range 3478 --access Allow
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-5349-tcp --priority 1050 --protocol Tcp --destination-port-range 5349 --access Allow

# Create virtual network and subnet
az network vnet create --resource-group deployment-test --name myVnet --subnet-name mySubnet

# Ensure the virtual network and subnet are fully created
sleep 30

# Create public IP address
az network public-ip create --resource-group deployment-test --name myPublicIP

# Create network interface and associate NSG
az network nic create --resource-group deployment-test --name myNic --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup --public-ip-address myPublicIP

# Ensure the NIC is fully created
sleep 30

# pick an image from ['CentOS85Gen2', 'Debian11', 'FlatcarLinuxFreeGen2', 'OpenSuseLeap154Gen2', 'RHELRaw8LVMGen2', 'SuseSles15SP3', 'Ubuntu2204', 'Win2022Datacenter', 'Win2022AzureEditionCore', 'Win2019Datacenter', 'Win2016Datacenter', 'Win2012R2Datacenter', 'Win2012Datacenter', 'Win2008R2SP1'].

# Create VM and show progress bar
az vm create \
  --resource-group deployment-test \
  --name jitsi-meet-vm \
  --nics myNic \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --size Standard_B1s \
  --availability-set "" \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --custom-data startup-script.sh &

# [Coming breaking change] In the coming release, the default behavior will be changed as follows when sku is Standard and zone is not provided: 
# For zonal regions, you will get a zone-redundant IP indicated by zones:["1","2","3"]; For non-zonal regions, you will get a non zone-redundant IP indicated by zones:null

# Get the PID of the az vm create command
pid=$!

# Show progress while the command is running
##show_progress $pid

# Get the public IP address of the VM
# public_ip=$(az vm show \
#   --resource-group deployment-test \
#   --name jitsi-meet-vm \
#   --show-details \
#   --query [publicIps] \
#   --output tsv)

# Wait for VM creation to complete
echo "Waiting for VM creation to complete..."
az vm wait --created --resource-group deployment-test --name jitsi-meet-vm

# Get the public IP address of the VM
public_ip=$(az vm list-ip-addresses --resource-group deployment-test --name jitsi-meet-vm --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" --output tsv)

# Verifying the VM creation
echo "VM creation complete. You can now SSH into the VM using your existing public key."
echo "Public IP address of the VM is: $public_ip"

# sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh anindya.mashmari@gmail.com