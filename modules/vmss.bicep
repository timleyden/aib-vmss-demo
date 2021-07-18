@description('The location into which the Azure resources should be deployed.')
param location string

@description('The resource ID of the image to deploy to the virtual machine.')
param vmssImageResourceId string

var vnetName = 'vmssvnet'
var vmssName = 'vmsssig'
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
          osType:'Windows'
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
                commandToExecute:'powershell.exe -ExecutionPolicy Unrestricted -Command "& Invoke-Expression -Command ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(\'${loadFileAsBase64('../scripts/vmss-configure-iis.ps1')}\'))+[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(\'${loadFileAsBase64('../scripts/vmss-sethostname.ps1')}\')))"'
              }
            }
          }
        ]
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

output loadBalancerPublicIPAddressFqdn string = network.outputs.loadBalancerPublicIPAddressFqdn
