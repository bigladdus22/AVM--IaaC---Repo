targetScope = 'tenant'

@description('The tenant root management group name. Use a unique value within the tenant.')
param rootManagementGroupName string = 'contoso-root'

@description('Display name for the root management group.')
param rootManagementGroupDisplayName string = 'Contoso Landing Zone Root'

@description('Platform management group name under the tenant root.')
param platformManagementGroupName string = 'platform'

@description('Display name for the platform management group.')
param platformManagementGroupDisplayName string = 'Platform'

@description('Landing zone management group name under the tenant root.')
param landingZoneManagementGroupName string = 'landing-zones'

@description('Display name for the landing zone management group.')
param landingZoneManagementGroupDisplayName string = 'Landing Zones'

@description('Sandbox management group name under the tenant root.')
param sandboxManagementGroupName string = 'sandbox'

@description('Display name for the sandbox management group.')
param sandboxManagementGroupDisplayName string = 'Sandbox'

@description('Approved Azure regions for landing zone workloads.')
param allowedLocations array = [
  'uksouth'
  'westeurope'
]

@description('Deployment region used for policy assignments. This is not the workload region set by allowedLocations.')
param policyAssignmentLocation string = 'uksouth'

type SubscriptionPlacement = {
  managementGroupName: 'platform' | 'landing-zones' | 'sandbox'
  subscriptionId: string
}

@description('Subscription-to-management-group placement map. Populate with the production subscription IDs for this tenant. Leave entries empty to skip placement.')
param subscriptionPlacements SubscriptionPlacement[] = [
  {
    managementGroupName: 'platform'
    subscriptionId: ''
  }
  {
    managementGroupName: 'landing-zones'
    subscriptionId: ''
  }
  {
    managementGroupName: 'sandbox'
    subscriptionId: ''
  }
]

module rootManagementGroup 'br/public:avm/res/management/management-group:0.2.0' = {
  name: 'root-management-group'
  scope: managementGroup(tenant().tenantId)
  params: {
    name: rootManagementGroupName
    displayName: rootManagementGroupDisplayName
    parentId: tenant().tenantId
    location: policyAssignmentLocation
    enableTelemetry: false
  }
}

module platformManagementGroupModule 'br/public:avm/res/management/management-group:0.2.0' = {
  name: 'platform-management-group'
  scope: managementGroup(rootManagementGroupName)
  params: {
    name: platformManagementGroupName
    displayName: platformManagementGroupDisplayName
    parentId: rootManagementGroupName
    location: policyAssignmentLocation
    enableTelemetry: false
  }
  dependsOn: [
    rootManagementGroup
  ]
}

module landingZoneManagementGroupModule 'br/public:avm/res/management/management-group:0.2.0' = {
  name: 'landing-zones-management-group'
  scope: managementGroup(rootManagementGroupName)
  params: {
    name: landingZoneManagementGroupName
    displayName: landingZoneManagementGroupDisplayName
    parentId: rootManagementGroupName
    location: policyAssignmentLocation
    enableTelemetry: false
  }
  dependsOn: [
    rootManagementGroup
  ]
}

module sandboxManagementGroupModule 'br/public:avm/res/management/management-group:0.2.0' = {
  name: 'sandbox-management-group'
  scope: managementGroup(rootManagementGroupName)
  params: {
    name: sandboxManagementGroupName
    displayName: sandboxManagementGroupDisplayName
    parentId: rootManagementGroupName
    location: policyAssignmentLocation
    enableTelemetry: false
  }
  dependsOn: [
    rootManagementGroup
  ]
}

resource platformManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  name: platformManagementGroupName
  scope: tenant()
}

resource landingZoneManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  name: landingZoneManagementGroupName
  scope: tenant()
}

resource sandboxManagementGroup 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  name: sandboxManagementGroupName
  scope: tenant()
}

module allowedLocationsPolicyAssignment 'br/public:avm/res/authorization/policy-assignment/mg-scope:0.1.0' = {
  name: 'allowed-locations-policy-assignment'
  scope: managementGroup(rootManagementGroupName)
  params: {
    name: 'allowed-locations'
    displayName: 'Allowed regions for landing zone workloads'
    description: 'Restricts resource deployments to the approved Azure regions at the root management group.'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf0374f8f2eb'
    enforcementMode: 'Default'
    location: policyAssignmentLocation
    enableTelemetry: false
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
  dependsOn: [
    rootManagementGroup
  ]
}

resource platformSubscriptions 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = [for placement in subscriptionPlacements: if (!empty(placement.subscriptionId) && placement.managementGroupName == 'platform') {
  parent: platformManagementGroup
  name: placement.subscriptionId
  dependsOn: [
    platformManagementGroupModule
  ]
}]

resource landingZoneSubscriptions 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = [for placement in subscriptionPlacements: if (!empty(placement.subscriptionId) && placement.managementGroupName == 'landing-zones') {
  parent: landingZoneManagementGroup
  name: placement.subscriptionId
  dependsOn: [
    landingZoneManagementGroupModule
  ]
}]

resource sandboxSubscriptions 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = [for placement in subscriptionPlacements: if (!empty(placement.subscriptionId) && placement.managementGroupName == 'sandbox') {
  parent: sandboxManagementGroup
  name: placement.subscriptionId
  dependsOn: [
    sandboxManagementGroupModule
  ]
}]

output rootManagementGroupId string = rootManagementGroup.outputs.resourceId
output platformManagementGroupId string = platformManagementGroupModule.outputs.resourceId
output landingZoneManagementGroupId string = landingZoneManagementGroupModule.outputs.resourceId
output sandboxManagementGroupId string = sandboxManagementGroupModule.outputs.resourceId
output assignedAllowedLocations array = allowedLocations
