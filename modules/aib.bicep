@description('The location into which the Azure resources should be deployed.')
param location string

var imageName = 'win2k19iis'
var imageIdentifier = {
  offer: 'Windows'
  publisher: 'Demo'
  sku: '2019iis'
}
var azureImageBuilderName = 'aibdemo'
var azureImageBuilderSource = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}
var azureImageBuilderIdentityName = 'aibuseridentity'
var sharedImageGalleryName = 'aibsig'
var roleDefinitionIds = {
  Owner: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  }
  Contributor: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  }
  Reader: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  }
}

resource image 'Microsoft.Compute/galleries/images@2020-09-30' = {
  parent: sharedImageGallery
  name: imageName
  location: location
  properties: {
    osState: 'Generalized'
    osType: 'Windows'
    identifier: imageIdentifier
  }
}

resource azureImageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' = {
  name: azureImageBuilderName
  location: location
  identity:{
    type:'UserAssigned'
    userAssignedIdentities:{
      '${azureImageBuilderIdentity.id}': {}
    }
  }
  properties:{
    source: azureImageBuilderSource
    customize: [
     {
        type: 'PowerShell'
        name: 'installIIS'
        runElevated: true
        inline: [
          loadTextContent('../scripts/aib-customize.ps1')
        ]
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: image.id
        replicationRegions: [
          location
        ]
        runOutputName: 'runoutputname'
      }
    ]
  }
}

resource azureImageBuilderIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: azureImageBuilderIdentityName
}

resource azureImageBuilderIdentityRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: sharedImageGallery
  name: guid(sharedImageGallery.id, azureImageBuilderIdentity.id, roleDefinitionIds.Contributor.id)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: azureImageBuilderIdentity.properties.principalId
    roleDefinitionId: roleDefinitionIds.Contributor.id
    description: 'Allows Azure Image Builder to write images to the shared image gallery.'
  }
}

resource sharedImageGallery 'Microsoft.Compute/galleries@2020-09-30' = {
  location: location
  name: sharedImageGalleryName
}

output imageResourceId string = image.id
output azureImageBuilderName string = azureImageBuilder.name
