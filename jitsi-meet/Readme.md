# Step 1: Install Azure CLI (Mac)
```
brew update && brew install azure-cli
```
# Step 2: Log in to Azure
Log in to your Azure account using the Azure CLI.
```
az login
```
Use Device Code Flow
If the web browser method is failing, you can try using the device code flow. This is often useful when the default az login method encounters issues.
```
az login --use-device-code
```
This command will prompt you to open a URL and enter a device code to authenticate.
## Specify the Tenant ID
```
az login --tenant TENANT_ID
```
Replace TENANT_ID with the ID of the tenant you want to log in to.
## Clear Cached Credentials
az account clear

# Step3: Create Resource Group
az group create --name deployment-test --location eastus

# Step4: Create the Virtual Machine
Use the --ssh-key-values parameter to specify the path to your existing public key.
```
az vm create \
  --resource-group deployment-test \
  --name jitsi-meet-vm \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --size Standard_B1s \
  --availability-set "" \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --custom-data startup-script.sh 
```
Here's what each parameter does:

* `--resource-group:` Specifies the resource group name.
* `--name:` Specifies the VM name.
* `--image:` Specifies the VM image to use (UbuntuLTS for the latest Ubuntu LTS version).
* `--admin-username:` Sets the admin username for the VM.
* `--ssh-key-values:` Provides the public SSH key file path to be used for authentication.
* `--custom-data:` Specifies a file containing the startup script to be executed on the VM.

# Step5: Verifying the Deployment

## SSH into the VM:
Use the existing SSH key to log into your VM:
```
ssh -i /path/to/your/private/key azureuser@<VM_PUBLIC_IP>
```

## Check Cloud-Init Logs:
View the cloud-init log to verify that the startup script ran correctly:
```
sudo less /var/log/cloud-init-output.log
```

## Check Services:
Ensure that the Jitsi Meet services are running:
```
sudo systemctl status prosody
sudo systemctl status jicofo
sudo systemctl status jitsi-videobridge2
```

## Access Jitsi Meet:
Open a web browser and navigate to http://meet.dizikloud.top.

# Additional steps for including NSG

## Step 1: Create the Resource Group
```
az group create --name deployment-test --location eastus
```

## Step 2: Create the Network Security Group
```
az network nsg create --resource-group deployment-test --name myNetworkSecurityGroup
```

## Step 3: Create NSG Rules for Required Ports
```
# Open port 22/tcp for SSH
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-ssh --priority 1000 --protocol Tcp --destination-port-range 22 --access Allow

# Open port 80/tcp for HTTP
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-http --priority 1010 --protocol Tcp --destination-port-range 80 --access Allow

# Open port 443/tcp for HTTPS
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-https --priority 1020 --protocol Tcp --destination-port-range 443 --access Allow

# Open port 10000/udp for Jitsi Meet
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-10000-udp --priority 1030 --protocol Udp --destination-port-range 10000 --access Allow

# Open port 3478/udp for STUN/TURN
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-3478-udp --priority 1040 --protocol Udp --destination-port-range 3478 --access Allow

# Open port 5349/tcp for STUN/TURN over TCP
az network nsg rule create --resource-group deployment-test --nsg-name myNetworkSecurityGroup --name allow-5349-tcp --priority 1050 --protocol Tcp --destination-port-range 5349 --access Allow
```

## Step 4: Create the Virtual Network and Subnet
```
az network vnet create --resource-group deployment-test --name myVnet --subnet-name mySubnet
```

## Step 5: Create a Public IP Address
```
az network public-ip create --resource-group deployment-test --name myPublicIP
```

## Step 6: Create the Network Interface and Associate the NSG
```
az network nic create --resource-group deployment-test --name myNic --vnet-name myVnet --subnet mySubnet --network-security-group myNetworkSecurityGroup --public-ip-address myPublicIP
```

## Step 7: Create the Virtual Machine
Use the existing public SSH key and startup script.
```
az vm create \
  --resource-group deployment-test \
  --name jitsi-meet-vm \
  --nics myNic \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --size Standard_B1s \
  --availability-set "" \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --custom-data startup-script.sh
```
