@description('The location into which the Azure resources should be deployed.')
param location string = 'australiaeast'

@description('The username for the administrator account on the VMSS instances.')
param vmssAdministratorUsername string = 'sysadmin'

@secure()
@description('The password for the administrator account on the VMSS instances.')
param vmssAdministratorPassword string 

/* This Bicep file does the following:
 - Deploys Azure Image Builder and a shared image gallery.
 - Runs Azure Image Builder to build an image.
 - Deploys a VM scale set that uses the image.
*/

module azureImageBuilder 'modules/aib.bicep' = {
  name: 'azure-image-builder'
  params: {
    location: location
  }
}

module azureImageBuilderRun 'modules/aib-run.bicep' = {
  name: 'azure-image-builder-run'
  params: {
    azureImageBuilderName: azureImageBuilder.outputs.azureImageBuilderName
  }
}

module vmss 'modules/vmss.bicep' = {
  name: 'vm-scale-set'
  dependsOn: [
    azureImageBuilderRun // Ensure that the image is actually built before we try to use it in a VMSS.
  ]
  params: {
    location: location
    vmssAdministratorUsername: vmssAdministratorUsername
    vmssAdministratorPassword: vmssAdministratorPassword
    vmssImageResourceId: azureImageBuilder.outputs.imageResourceId
  }
}
