@description('The location into which the Azure resources should be deployed.')
param location string

@description('The resource ID of the image to deploy to the virtual machine.')
param vmssImageResourceId string

@description('The username for the administrator account on the VMSS instances.')
param vmssAdministratorUsername string

@secure()
@description('The password for the administrator account on the VMSS instances.')
param vmssAdministratorPassword string 

var vnetName = 'vmssvnet'
var vmssName = 'vmsssig'
var vmssComputerNamePrefix = 'vmsssig'
var vmssSku = {
  capacity: 2
  name: 'Standard_D1_v2'
}
var vmssUpgradePolicy = {
  mode: 'Manual'
}
var vmssDiagnosticStorageAccountName = 'strdiag${uniqueString(resourceGroup().id)}'
var vmssDiagnosticStorageAccountSku = {
  name:'Standard_LRS'
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  name: vmssName
  location: location
  sku: vmssSku
  properties: {
    overprovision: true
    upgradePolicy: vmssUpgradePolicy
    orchestrationMode: 'Uniform'
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          id: vmssImageResourceId
        }
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'customScriptExtension'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              protectedSettings: {
                commandToExecute:'powershell.exe -ExecutionPolicy Unrestricted -EncodedCommand "UwBlAHQALQBDAG8AbgB0AGUAbgB0ACAAQwA6AFwAaQBuAGUAdABwAHUAYgBcAHcAdwB3AHIAbwBvAHQAXABkAGUAZgBhAHUAbAB0AC4AYQBzAHAAeAAgAC0AVgBhAGwAdQBlACAAIgA8ACUAIABAACAAUABhAGcAZQAgAEwAYQBuAGcAdQBhAGcAZQA9AGAAIgBDACMAYAAiACAAJQA+AGAAbgA8ACUAYABuAGYAbwByAGUAYQBjAGgAIAAoAHMAdAByAGkAbgBnACAAdgBhAHIAIABpAG4AIABSAGUAcQB1AGUAcwB0AC4AUwBlAHIAdgBlAHIAVgBhAHIAaQBhAGIAbABlAHMAKQBgAG4AewBgAG4AIAAgAFIAZQBzAHAAbwBuAHMAZQAuAFcAcgBpAHQAZQAoAHYAYQByACAAKwAgAGAAIgAgAGAAIgAgACsAIABSAGUAcQB1AGUAcwB0AFsAdgBhAHIAXQAgACsAIABgACIAPABiAHIAPgBgACIAKQA7AGAAbgB9AGAAbgAlAD4AIgAgACAALQBOAG8ATgBlAHcAbABpAG4AZQA7AGkAZgAoAHQAZQBzAHQALQBwAGEAdABoACAAQwA6AFwAaQBuAGUAdABwAHUAYgBcAHcAdwB3AHIAbwBvAHQAXABpAGkAcwBzAHQAYQByAHQALgBoAHQAbQApAHsAIAByAGUAbgBhAG0AZQAtAEkAdABlAG0AIABDADoAXABpAG4AZQB0AHAAdQBiAFwAdwB3AHcAcgBvAG8AdABcAGkAaQBzAHMAdABhAHIAdAAuAGgAdABtACAAaQBpAHMAcwB0AGEAcgB0AC4AaAB0AG0AbAAuAGEAcgBjAGgAaQB2AGUAfQA="'
              }
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: vmssComputerNamePrefix
        adminUsername: vmssAdministratorUsername
        adminPassword: vmssAdministratorPassword
        windowsConfiguration: {}
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: vmssDiagnosticStorage.properties.primaryEndpoints.blob
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              networkSecurityGroup: {
                id: network.outputs.networkSecurityGroupResourceId
              }
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: vnet::defaultSubnet.id
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: network.outputs.loadBalancerBackendAddressPoolResourceId
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: network.outputs.loadBalancerInboundNatPoolResourceId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

resource vmssDiagnosticStorage 'Microsoft.Storage/storageAccounts@2021-04-01'={
  location: location
  name: vmssDiagnosticStorageAccountName
  kind: 'StorageV2'
  sku: vmssDiagnosticStorageAccountSku
}

module network 'vmss-network.bicep' = {
  name: 'vmss-network'
  params: {
    vnetName: vnetName    
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName

  resource defaultSubnet 'subnets' existing = {
    name: 'default'
  }
}
