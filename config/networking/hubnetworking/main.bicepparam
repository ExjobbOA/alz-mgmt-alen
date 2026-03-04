using '../../../platform/templates/networking/hubnetworking/main.bicep'

var location          = readEnvironmentVariable('LOCATION_PRIMARY')
var locationSecondary = readEnvironmentVariable('LOCATION_SECONDARY', '')
var enableTelemetry   = bool(readEnvironmentVariable('ENABLE_TELEMETRY', 'true'))

param parLocations = [
  location
  locationSecondary
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = enableTelemetry

// Resource Group Parameters
param parHubNetworkingResourceGroupNamePrefix = 'rg-alz-conn'
param parDnsResourceGroupNamePrefix = 'rg-alz-dns'
param parDnsPrivateResolverResourceGroupNamePrefix = 'rg-alz-dnspr'

// Hub Networking Parameters
param hubNetworks = [
  {
    name: 'vnet-alz-${location}'
    location: location
    addressPrefixes: [
      '10.0.0.0/22'
    ]
    deployPeering: true
    dnsServers: []
    peeringSettings: [
      {
        remoteVirtualNetworkName: 'vnet-alz-${locationSecondary}'
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
      }
    ]
    // Subnets are omitted because all hub resources are disabled (deployAzureFirewall,
    // deployBastion, deployVpnGateway, deployExpressRouteGateway, deployDnsPrivateResolver
    // are all false). ALZ policy requires every subnet to have an NSG, so pre-creating
    // placeholder subnets for undeployed resources would fail policy validation.
    //
    // To re-enable subnets when enabling a resource, add the relevant entry and set the
    // corresponding deploy* flag to true:
    //   { name: 'AzureFirewallSubnet',           addressPrefix: '10.0.0.0/26'   }  // + deployAzureFirewall: true
    //   { name: 'AzureFirewallManagementSubnet',  addressPrefix: '10.0.0.192/26' }  // + deployAzureFirewall: true (Standard/Premium tier)
    //   { name: 'AzureBastionSubnet',             addressPrefix: '10.0.0.64/26'  }  // + deployBastion: true
    //   { name: 'GatewaySubnet',                  addressPrefix: '10.0.0.128/27' }  // + deployVpnGateway or deployExpressRouteGateway: true
    //   { name: 'DNSPrivateResolverInboundSubnet',  addressPrefix: '10.0.0.160/28', delegation: 'Microsoft.Network/dnsResolvers' }  // + deployDnsPrivateResolver: true
    //   { name: 'DNSPrivateResolverOutboundSubnet', addressPrefix: '10.0.0.176/28', delegation: 'Microsoft.Network/dnsResolvers' }  // + deployDnsPrivateResolver: true
    subnets: []
    azureFirewallSettings: {
      deployAzureFirewall: false
      azureFirewallName: 'afw-alz-${location}'
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-afw-alz-${location}'
      }
      managementIPAddressObject: {
        name: 'pip-afw-mgmt-alz-${location}'
      }
    }
    bastionHostSettings: {
      deployBastion: false
      bastionHostSettingsName: 'bas-alz-${location}'
      skuName: 'Standard'
    }
    vpnGatewaySettings: {
      deployVpnGateway: false
      name: 'vgw-alz-${location}'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
      asn: 65515
    }
    expressRouteGatewaySettings: {
      deployExpressRouteGateway: false
      name: 'ergw-alz-${location}'
    }
    privateDnsSettings: {
      deployPrivateDnsZones: false
      deployDnsPrivateResolver: false
      privateDnsResolverName: 'dnspr-alz-${location}'
      privateDnsZones: []
    }
    ddosProtectionPlanSettings: {
      deployDdosProtectionPlan: false
      name: 'ddos-alz-${location}'
    }
  }
  {
    name: 'vnet-alz-${locationSecondary}'
    location: locationSecondary
    addressPrefixes: [
      '10.1.0.0/22'
    ]
    deployPeering: true
    dnsServers: []
    peeringSettings: [
      {
        remoteVirtualNetworkName: 'vnet-alz-${location}'
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
      }
    ]
    // See primary hub above for subnet reference — same logic applies (10.1.x.x range).
    subnets: []
    azureFirewallSettings: {
      deployAzureFirewall: false
      azureFirewallName: 'afw-alz-${locationSecondary}'
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-afw-alz-${locationSecondary}'
      }
      managementIPAddressObject: {
        name: 'pip-afw-mgmt-alz-${locationSecondary}'
      }
    }
    bastionHostSettings: {
      deployBastion: false
      bastionHostSettingsName: 'bas-alz-${locationSecondary}'
      skuName: 'Standard'
    }
    vpnGatewaySettings: {
      deployVpnGateway: false
      name: 'vgw-alz-${locationSecondary}'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
      asn: 65515
    }
    expressRouteGatewaySettings: {
      deployExpressRouteGateway: false
      name: 'ergw-alz-${locationSecondary}'
    }
    privateDnsSettings: {
      deployPrivateDnsZones: false
      deployDnsPrivateResolver: false
      privateDnsResolverName: 'dnspr-alz-${locationSecondary}'
      privateDnsZones: [
        'privatelink.{regionName}.azurecontainerapps.io'
        'privatelink.{regionName}.kusto.windows.net'
        'privatelink.{regionName}.azmk8s.io'
        'privatelink.{regionName}.prometheus.monitor.azure.com'
        'privatelink.{regionCode}.backup.windowsazure.com'
      ]
    }
    ddosProtectionPlanSettings: {
      deployDdosProtectionPlan: false
    }
  }
]
