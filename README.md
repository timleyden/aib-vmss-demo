# Azure Image Builder with Virtual Machine Scale Sets demo

This repo contains a set of Bicep files that demonstrate Azure Image Builder (AIB) and Virtual Machine Scale Sets (VMSS) working together.

For the purposes of the demonstration, AIB takes a Windows Server 2019 image from the Azure Marketplace and then adds the IIS roles and features. AIB then publishes the resulting image into a shared image gallery. Once the image has been successfully created, a VMSS is then created from that image.

We have also demonstrated how you can use a custom script extension on the scale set to perform post-boot configuration on the VMs.

![Napkin architecture image](./napkinarch.jpg "Napkin architecture")

## To deploy this sample

1. Create a resource group.

1. Deploy the _main.bicep_ file, such as by running the following command:
   ```
   az deployment group create -g MyResourceGroup -f ./main.bicep
   ```

   The deployment will take some time - potentially an hour or more.

1. Once the deployment succeeds, you can access the VMSS through a web browser, or using RDP.

## Note on Bicep code

The _main.bicep_ file does the following, in sequence:

1. Deploys Azure Image Builder and a shared image gallery.
1. Runs Azure Image Builder to build an image.
1. Deploys a VM scale set that uses the image.

The second step is necessary because AIB requires you to explicitly run the build process. An ARM deployment script is used to execute the operation.
