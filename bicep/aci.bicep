targetScope = 'resourceGroup'

param ipsettings object
param location string
// param myobjectid string
// param myip string
param prefix string
param subnetid string

resource aci 'Microsoft.ContainerInstance/containerGroups@2022-09-01' = {
  name: prefix
  location: location
  properties: {
    containers: [
      {
        name: prefix
        properties: {
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld'
          ports:[
            {
              port: 80
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      ip: ipsettings.aciip
      ports: [
        {
          port: 80
        }
      ]
      type: 'Private'
      // dnsNameLabel: prefix // only supported with public ips
    }
    subnetIds:[
      {
        id: subnetid
        name: 'aci'
      }
    ]
  }
}

output aciip string = aci.properties.ipAddress.ip


