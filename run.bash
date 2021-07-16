
az group create --resource-group my-rg --location australiaeast
az deployment group create -f ./aib.bicep -g my-rg 
az resource invoke-action \
     --resource-group my-rg \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n aibdemo \
     --action Run 