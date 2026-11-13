// Bicep: 2 VNet + peering 2 chieu.
// Thuc hanh: az bicep build --file iac/bicep/vnet-peering.bicep
// Doc de tra loi cau hoi trong iac/README.md

@description('Region cho ca 2 VNet')
param location string = resourceGroup().location

@description('Ten VNet hub va dia chi')
param hubName string = 'vnet-hub-bicep'
param hubPrefix string = '10.50.0.0/16'

@description('Ten VNet spoke va dia chi')
param spokeName string = 'vnet-spoke1-bicep'
param spokePrefix string = '10.51.0.0/16'

var hubSubnetName = 'snet-hub'
var spokeSubnetName = 'snet-app'

resource hub 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: hubName
  location: location
  tags: {
    env: 'lab'
    managedBy: 'bicep'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [hubPrefix]
    }
    subnets: [
      {
        name: hubSubnetName
        properties: { addressPrefix: '10.50.1.0/24' }
      }
    ]
  }
}

resource spoke 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: spokeName
  location: location
  tags: {
    env: 'lab'
    managedBy: 'bicep'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [spokePrefix]
    }
    subnets: [
      {
        name: spokeSubnetName
        properties: { addressPrefix: '10.51.1.0/24' }
      }
    ]
  }
}

// Peering hub -> spoke (bat buoc cho traffic qua NVA)
resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hub
  name: 'hub-to-spoke'
  properties: {
    remoteVirtualNetwork: { id: spoke.id }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Peering spoke -> hub (phai tao ca 2 chieu)
resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: spoke
  name: 'spoke-to-hub'
  properties: {
    remoteVirtualNetwork: { id: hub.id }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

output hubId string = hub.id
output spokeId string = spoke.id
output hubSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', hubName, hubSubnetName)
