@description('The name of the Azure Image Builder resource.')
param azureImageBuilderName string

var deploymentScriptName = 'aib-run'
var userAssignedIdentityName = 'configDeployer'
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '3.0'
    environmentVariables: [
      {
        name: 'AzureImageBuilderResourceId'
        value: azureImageBuilder.id
      }
    ]
    scriptContent: '''
      Invoke-AzResourceAction -Action Run -ResourceId $env:AzureImageBuilderResourceId
    '''
    retentionInterval: 'P1D'
  }
  dependsOn: [
    roleAssignment
  ]
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: resourceGroup().location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(azureImageBuilder.id, userAssignedIdentity.id, contributorRoleDefinitionId)
  scope: azureImageBuilder
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource azureImageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2020-02-14' existing = {
  name: azureImageBuilderName
}
