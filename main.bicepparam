using './main.bicep'

param rootManagementGroupName = 'contoso-root'
param rootManagementGroupDisplayName = 'Contoso Landing Zone Root'
param platformManagementGroupName = 'platform'
param platformManagementGroupDisplayName = 'Platform'
param landingZoneManagementGroupName = 'landing-zones'
param landingZoneManagementGroupDisplayName = 'Landing Zones'
param sandboxManagementGroupName = 'sandbox'
param sandboxManagementGroupDisplayName = 'Sandbox'
param allowedLocations = [
  'uksouth'
  'westeurope'
]
param policyAssignmentLocation = 'uksouth'
param subscriptionPlacements = [
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
