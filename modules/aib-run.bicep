@description('The location into which the Azure resources should be deployed.')
param location string

@description('The name of the Azure Image Builder resource.')
param azureImageBuilderName string

var deploymentScriptName = 'aib-run'
var userAssignedIdentityName = 'configDeployer'
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

// This Bicep file triggers the 'run' action on the Azure Image Builder. Because this is an action, you can't do this declaratively, so a deployment script is used.

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.9.1'
    environmentVariables: [
      {
        name: 'AzureImageBuilderResourceId'
        value: azureImageBuilder.id
      }
    ]
    scriptContent: '''
      az image builder run --ids $AzureImageBuilderResourceId
    '''
    retentionInterval: 'P1D'
  }
  dependsOn: [
    roleAssignment
  ]
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(azureImageBuilder.id, userAssignedIdentity.id, contributorRoleDefinitionId)
  scope: azureImageBuilder
  properties: {
    principalType: 'ServicePrincipal'
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: contributorRoleDefinitionId
    description: 'Allows the deployment script to execute the Run action on the Azure Image Builder resource.'
  }
}

resource azureImageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' existing = {
  name: azureImageBuilderName
}
