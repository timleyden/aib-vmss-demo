@description('The location into which the Azure resources should be deployed.')
param location string = 'australiaeast'

@description('The name of the virtual network.')
param vnetName string

var vnetAddressPrefix = '10.0.0.0/16'
var vnetDefaultSubnetAddressPrefix = '10.0.0.0/24'
var networkSecurityGroupName = 'AllowRdpHttp'
var loadBalancerPublicIPAddressName = '${loadBalancerName}-pip'
var loadBalancerName = 'vmsslb'
var loadBalancerFrontendIPConfigurationName = '${loadBalancerName}-feipconfig'
var loadBalancerBackendAddressPoolName = '${loadBalancerName}-bepool'
var loadBalancerProbeName = '${loadBalancerName}-probe'
var loadBalancerInboundNatPoolName = '${loadBalancerName}-natpool'
var loadBalancerRuleName = '${loadBalancerName}-roundrobinrule'

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
}

// WARNING: This network security group is not recommended for production use, since it is too permissive. It's included here to simplify the demonstration.
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01'={
  location: location
  name: networkSecurityGroupName
  properties: {
    securityRules: [
      {
        name: 'AllowRDPHTTP'
        properties: {
          access: 'Allow'
          destinationPortRanges: [
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

output networkSecurityGroupResourceId string = networkSecurityGroup.id
output loadBalancerBackendAddressPoolResourceId string = loadBalancer.properties.backendAddressPools[0].id
output loadBalancerInboundNatPoolResourceId string = loadBalancer.properties.inboundNatPools[0].id
