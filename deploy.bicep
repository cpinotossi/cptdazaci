targetScope='subscription'

var parameters = json(loadTextContent('parameters.json'))
// var location = resourceGroup().location
param location string = deployment().location
param myobjectid string
param myip string
param prefix string
param ipsettings object = {
  vnet: '10.1.0.0/16'
  prefix: '10.1.0.0/24'
  aci: '10.1.1.0/24'
  acipub: '10.1.3.0/24'
  aciip: '10.1.1.4'
  AzureBastionSubnet: '10.1.2.0/24'
  prefixvmlin: '10.1.0.4'
  myip: myip
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: prefix
  location: location
}

module vnetModule 'bicep/vnet.bicep' = {
  scope: resourceGroup(prefix)
  name: 'vnetDeploy'
  params: {
    prefix: prefix
    location: location
    ipsettings: ipsettings
    acisubnetname: 'aci'
    acipubsubnetname: 'acipub'
  }
  dependsOn:[
    rg
  ]
}

module vmModule 'bicep/vm.linux.bicep' = {
  scope: resourceGroup(prefix)
  name: 'vmDeploy'
  params: {
    prefix: prefix
    location: location
    username: parameters.username
    password: parameters.password
    myObjectId: myobjectid
    postfix: 'lin'
    privateip: ipsettings.prefixvmlin
  }
  dependsOn:[
    vnetModule
  ]
}

module aciModule 'bicep/aci.bicep' = {
  scope: resourceGroup(prefix)
  name: 'aciDeploy'
  params: {
    prefix: prefix
    location: location
    subnetid: vnetModule.outputs.acisubnetid
    ipsettings:ipsettings
  }
  dependsOn:[
    vnetModule
  ]
}

module acipubModule 'bicep/aci.pub.bicep' = {
  scope: resourceGroup(prefix)
  name: 'acipubDeploy'
  params: {
    prefix: '${prefix}pub'
    location: location
    subnetid: vnetModule.outputs.acipubsubnetid
  }
  dependsOn:[
    vnetModule
  ]
}
