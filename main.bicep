@description('The location into which the Azure resources should be deployed.')
param location string = 'australiaeast'

@description('The username for the administrator account on the VMSS instances.')
param vmssAdministratorUsername string = 'sysadmin'

@secure()
@description('The password for the administrator account on the VMSS instances.')
param vmssAdministratorPassword string 

module azureImageBuilder 'modules/aib.bicep' = {
  name: 'azure-image-builder'
  params: {
    location: location
    adminuser: vmssAdministratorUsername
    vmssAdministratorPassword:vmssAdministratorPassword
  }
}

module azureImageBuilderRun 'modules/aib-run.bicep' = {
  name: 'azure-image-builder-run'
  params: {
    azureImageBuilderName: azureImageBuilder.outputs.azureImageBuilderName
    location:location  
    runOutputName:azureImageBuilder.outputs.azureImageBuilderRunOutputName
  }
}
module imageVersion 'modules/sig-imagetemplate.bicep'={
  name:'image-version'  
  dependsOn:[
    azureImageBuilderRun
  ]
  params:{
    azureImageBuilderName: azureImageBuilder.outputs.azureImageBuilderName
    imageReferenceName:azureImageBuilder.outputs.imageResourceName
    location:location
    runOutputName:azureImageBuilder.outputs.azureImageBuilderRunOutputName
    storageAccountId:azureImageBuilderRun.outputs.imageStorageId
  }
}

module vmss 'modules/vmss.bicep' = {
  name: 'vm-scale-set'
  dependsOn: [
    imageVersion // Ensure that the image is actually built before we try to use it in a VMSS.
  ]
  params: {
    location: location
    vmssImageResourceId: azureImageBuilder.outputs.imageResourceId
  }
}

output loadBalancerPublicIPAddressFqdn string = vmss.outputs.loadBalancerPublicIPAddressFqdn
