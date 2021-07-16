@description('The location into which the Azure resources should be deployed.')
param location string = 'australiaeast'

@description('TODO')
param imageid string = '/subscriptions/3af535d9-6651-4c1b-b0f6-d55561e42bb0/resourceGroups/my-rg/providers/Microsoft.Compute/galleries/aibsig/images/win2k19iis'

@secure()
@description('TODO')
param vmssAdministratorPassword string 

var vnetName = 'vmssvnet'
var vnetAddressPrefix = '10.0.0.0/16'
var vnetDefaultSubnetAddressPrefix = '10.0.0.0/24'
var loadBalancerPublicIPAddressName = '${loadBalancerName}-pip'
var vmssDiagnosticStorageAccountName = 'strdiag${uniqueString(resourceGroup().id)}'
var vmssDiagnosticStorageAccountSku = {
  name:'Standard_LRS'
  tier:'Standard'
}
var loadBalancerName = 'vmsslb'
var networkSecurityGroupName = 'AllowRdpHttp'

var vmssName = 'vmsssig'
var vmssSku = {
  capacity: 2
  name: 'Standard_D1_v2'
}

@allowed([
  'Manual'
  'Automatic'
  'Rolling'
])
param vmssUpgradePolicy string = 'Manual'

param vmssAdministratorUsername string = 'sysadmin'
var vmssComputerNamePrefix = 'vmsssig'

// WARNING: This network security group is not recommended for production use, since it is too permissive. It's included here to simplify the demonstration.
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01'={
  location: location
  name: networkSecurityGroupName
  properties:{
    securityRules: [
      {
        name: 'AllowRDPHTTP'
        properties: {
          access: 'Allow'
          destinationPortRanges:[
            '3389'
            '80'
          ]
          direction: 'Inbound'
          protocol: 'Tcp'
          priority: 100
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'

        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: vnetDefaultSubnetAddressPrefix
        }
      }
    ]
  }

  resource defaultSubnet 'subnets' existing = {
    name: 'default'
  }
}

resource loadBalancerPublicIPAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: loadBalancerPublicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: loadBalancerName
    }
  }
}

var loadBalancerFrontendIPConfigurationName = '${loadBalancerName}-feipconfig'
var loadBalancerBackendAddressPoolName = '${loadBalancerName}-bepool'
var loadBalancerProbeName = '${loadBalancerName}-probe'
var loadBalancerInboundNatPoolName = '${loadBalancerName}-natpool'
var loadBalancerRuleName = '${loadBalancerName}-roundrobinrule'

resource loadBalancer 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: loadBalancerFrontendIPConfigurationName
        properties: {
          publicIPAddress: {
            id: loadBalancerPublicIPAddress.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: loadBalancerBackendAddressPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: loadBalancerRuleName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFrontendIPConfigurationName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, loadBalancerBackendAddressPoolName)
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, loadBalancerProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: loadBalancerProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatPools: [
      {
        name: loadBalancerInboundNatPoolName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, loadBalancerFrontendIPConfigurationName)
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50100
          backendPort: 3389
        }
      }
    ]
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  name: vmssName
  location: location
  sku: vmssSku
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: vmssUpgradePolicy
    }
    orchestrationMode: 'Uniform'
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          id: imageid
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
              protectedSettings: { // TODO
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
                id: networkSecurityGroup.id
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
                        id: loadBalancer.properties.backendAddressPools[0].id
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: loadBalancer.properties.inboundNatPools[0].id
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
