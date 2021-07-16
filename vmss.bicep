param location string = 'australiaeast'
param imageid string = '/subscriptions/3af535d9-6651-4c1b-b0f6-d55561e42bb0/resourceGroups/my-rg/providers/Microsoft.Compute/galleries/aibsig/images/win2k19iis'
@secure()
param adminPassword string 
var lbname = 'vmsslb'
resource diagStorage 'Microsoft.Storage/storageAccounts@2021-04-01'={
  location:location
  name:'strdiag${uniqueString(resourceGroup().id)}'
  kind:'StorageV2'
  sku:{
    name:'Standard_LRS'
    tier:'Standard'
  }
}
resource allowports 'Microsoft.Network/networkSecurityGroups@2021-02-01'={
  location:location
  name:'AllowRdpHttp'
  properties:{
    securityRules:[
      {
        name:'AllowRDPHTTP'
        properties:{
          access:'Allow'
          destinationPortRanges:[
            '3389'
            '80'
          ]
          direction:'Inbound'
          protocol:'Tcp'
          priority:100
          sourceAddressPrefix:'*'
          sourcePortRange:'*'
          destinationAddressPrefix:'*'

        }
      }
    ]
  }
}
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vmssvnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}
resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${lbname}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${lbname}'
    }
  }
}
resource loadbalancer 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: lbname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: '${lbname}-feipconfig'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: '${lbname}-bepool'
      }
    ]
    loadBalancingRules: [
      {
        name: '${lbname}-roundrobinrule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${lbname}', '${lbname}-feipconfig')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', '${lbname}', '${lbname}-bepool')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', '${lbname}', '${lbname}-probe')
          }
        }
      }
    ]
    probes: [
      {
        name: '${lbname}-probe'
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
        name: '${lbname}-natpool'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', '${lbname}', '${lbname}-feipconfig')
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
  name: 'vmsssig'
  location: location
  sku: {
    capacity: 2
    name: 'Standard_D1_v2'
  }
  properties: {
    overprovision: true
    upgradePolicy: {
      mode: 'Manual'
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
      extensionProfile:{
        extensions:[
          {
            name:'customScriptExtension'
            properties:{
              publisher:'Microsoft.Compute'
              type:'CustomScriptExtension'
              typeHandlerVersion:'1.10'
              protectedSettings:{
                commandToExecute:'powershell.exe -ExecutionPolicy Unrestricted -EncodedCommand "UwBlAHQALQBDAG8AbgB0AGUAbgB0ACAAQwA6AFwAaQBuAGUAdABwAHUAYgBcAHcAdwB3AHIAbwBvAHQAXABkAGUAZgBhAHUAbAB0AC4AYQBzAHAAeAAgAC0AVgBhAGwAdQBlACAAIgA8ACUAIABAACAAUABhAGcAZQAgAEwAYQBuAGcAdQBhAGcAZQA9AGAAIgBDACMAYAAiACAAJQA+AGAAbgA8ACUAYABuAGYAbwByAGUAYQBjAGgAIAAoAHMAdAByAGkAbgBnACAAdgBhAHIAIABpAG4AIABSAGUAcQB1AGUAcwB0AC4AUwBlAHIAdgBlAHIAVgBhAHIAaQBhAGIAbABlAHMAKQBgAG4AewBgAG4AIAAgAFIAZQBzAHAAbwBuAHMAZQAuAFcAcgBpAHQAZQAoAHYAYQByACAAKwAgAGAAIgAgAGAAIgAgACsAIABSAGUAcQB1AGUAcwB0AFsAdgBhAHIAXQAgACsAIABgACIAPABiAHIAPgBgACIAKQA7AGAAbgB9AGAAbgAlAD4AIgAgACAALQBOAG8ATgBlAHcAbABpAG4AZQA7AGkAZgAoAHQAZQBzAHQALQBwAGEAdABoACAAQwA6AFwAaQBuAGUAdABwAHUAYgBcAHcAdwB3AHIAbwBvAHQAXABpAGkAcwBzAHQAYQByAHQALgBoAHQAbQApAHsAIAByAGUAbgBhAG0AZQAtAEkAdABlAG0AIABDADoAXABpAG4AZQB0AHAAdQBiAFwAdwB3AHcAcgBvAG8AdABcAGkAaQBzAHMAdABhAHIAdAAuAGgAdABtACAAaQBpAHMAcwB0AGEAcgB0AC4AaAB0AG0AbAAuAGEAcgBjAGgAaQB2AGUAfQA="'
              }
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: 'vmsssig'
        adminUsername: 'sysadmin'
        adminPassword: adminPassword
        windowsConfiguration: {}
      }
      diagnosticsProfile:{
        bootDiagnostics:{
          enabled:true
          storageUri:diagStorage.properties.primaryEndpoints.blob
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              networkSecurityGroup:{
                id:allowports.id
              }
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: '${vnet.properties.subnets[0].id}'
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: loadbalancer.properties.backendAddressPools[0].id
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: loadbalancer.properties.inboundNatPools[0].id
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
