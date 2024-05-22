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

