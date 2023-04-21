targetScope='resourceGroup'

param prefix string = 'cptd'
param location string = 'eastus'
param ipsettings object
param acisubnetname string
param acipubsubnetname string

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: prefix
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        ipsettings.vnet
      ]
    }
    subnets: [
      {
        name: prefix
        properties: {
          addressPrefix: ipsettings.prefix
        }
      }
      {
        name: acisubnetname
        properties: {
          addressPrefix: ipsettings.aci
          delegations: [
            {
              name: 'Microsoft.ContainerInstance.containerGroups'
              // id: '${resourceId('Microsoft.Network/virtualNetworks/subnets', prefix, 'aci')}/delegations/${prefix}'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
              // type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: acipubsubnetname
        properties: {
          addressPrefix: ipsettings.acipub
          delegations: [
            {
              name: 'Microsoft.ContainerInstance.containerGroups'
              // id: '${resourceId('Microsoft.Network/virtualNetworks/subnets', prefix, 'aci')}/delegations/${prefix}'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
              // type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: ipsettings.AzureBastionSubnet
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource pubipbastion 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-09-01' = {
  name: '${prefix}bastion'
  location: location
  sku: {
    name:'Standard'
  }
  properties: {
    dnsName:'${prefix}.bastion.azure.com'
    enableTunneling: true
    enableShareableLink: true
    ipConfigurations: [
      {
        name: '${prefix}bastion'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubipbastion.id
          }
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: prefix
  location: location
  properties:{
    securityRules:[
      {
        name:prefix
        properties:{
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: '*'
          destinationAddressPrefix:'*'
          sourceAddressPrefix: ipsettings.myip
          sourcePortRange:'*'
          destinationPortRange:'*'
        }
      }
    ]
  }
}



resource pdns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location:'global'
  name: '${prefix}.io'
}

resource pdnslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: pdns
  name: prefix
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource pdnsz 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: pdns
  name: 'app1'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: ipsettings.aciip
      }
    ]
  }
}

output acisubnetid string = resourceId('Microsoft.Network/virtualNetworks/subnets', prefix, acisubnetname)
output acipubsubnetid string = resourceId('Microsoft.Network/virtualNetworks/subnets', prefix, acipubsubnetname)
