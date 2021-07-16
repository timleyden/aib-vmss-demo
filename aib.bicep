
param location string = 'australiaeast'
var roleDefinitionId = {
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

resource uaidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: 'aibuseridentity'
}
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(sig.id, uaidentity.id, roleDefinitionId.Contributor.id)
  scope: sig
  properties: {
    principalType: 'ServicePrincipal'
    principalId: uaidentity.properties.principalId
    roleDefinitionId: roleDefinitionId.Contributor.id
  }
}
resource sig 'Microsoft.Compute/galleries@2020-09-30' = {
  location: location
  name: 'aibsig'
}
resource image 'Microsoft.Compute/galleries/images@2020-09-30' = {
  parent:sig
  name: 'win2k19iis'
  location: location
  properties: {
    osState: 'Generalized'
    osType: 'Windows'
    identifier: {
      offer: 'Windows'
      publisher: 'Demo'
      sku: '2019iis'
    }
  }
}
resource aib 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14'={
  name:'aibdemo'
  location: location
  identity:{
    type:'UserAssigned'
    userAssignedIdentities:{
      '${uaidentity.id}': {}
    }
  }
  properties:{
   source:{
      type:'PlatformImage'
      publisher:'MicrosoftWindowsServer'
      offer:'WindowsServer'
      sku:'2019-Datacenter'
      version:'latest'
    }
    customize:[
      {
        type:'PowerShell'
        name:'installIIS'
        runElevated:true
        inline:[
          'Install-WindowsFeature -Name Web-Mgmt-Tools,Web-App-Dev,Web-Security,Web-Performance, Web-Webserver,Web-Application-Proxy -IncludeAllSubFeature'
        ]
      }
    ]
   distribute:[
     {
       type:'SharedImage'
       galleryImageId:image.id
       replicationRegions:[
        location
        ]
       runOutputName:'runoutputname'
     }
   ]
  }
}
output imageid string = image.id
