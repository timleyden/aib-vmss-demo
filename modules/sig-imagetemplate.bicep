@description('The location into which the Azure resources should be deployed.')
param location string
@description('The name of the Azure Image Builder resource.')
param azureImageBuilderName string
@description('The name of the Azure Image Builder resource.')
param imageReferenceName string
param runOutputName string
param storageAccountId string
var imageVersionName = '1.1.1'

resource imagedef 'Microsoft.Compute/galleries/images@2020-09-30' existing = {
  name:imageReferenceName
}
resource azureImageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' existing = {
  name: azureImageBuilderName
}
//todo: this module exists because we had to wait for run to finish before we could reference runoutput
resource runOutput 'Microsoft.VirtualMachineImages/imageTemplates/runOutputs@2020-02-14' existing = {
  
  parent: azureImageBuilder
  name: runOutputName

}
resource azureImageVersion 'Microsoft.Compute/galleries/images/versions@2020-09-30'={
  parent:imagedef
  name:imageVersionName
  location:location
  properties:{
    storageProfile:{
      osDiskImage:{
        source:{
          uri:runOutput.properties.artifactUri
          id:storageAccountId
        }
        hostCaching:'ReadOnly'
      }

    }
    
  }

}
output runOutput string = runOutput.properties.artifactUri
