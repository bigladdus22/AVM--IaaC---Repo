# Azure Landing Zone baseline

A minimal, reusable tenant-governance baseline written in Bicep. It creates a root management group with platform, landing-zones, and sandbox children using the AVM management-group module; assigns the Azure built-in **Allowed locations** policy through the AVM policy-assignment module; and can place explicitly listed subscriptions into those groups.

The template is governance-focused. It does not deploy networking, monitoring, or workload resources.

## Files

- `main.bicep` — tenant-scope deployment.
- `main.bicepparam` — editable Bicep parameters. Subscription IDs are blank by default, so no subscriptions are moved until IDs are explicitly supplied.
- `parameters.example.json` — equivalent JSON parameter-file example.

## Configure

Choose management-group names that are unique in your tenant and customize their display names. Set `allowedLocations` to approved workload regions and `policyAssignmentLocation` to the region used to store the policy assignment. Add only the subscription GUIDs you intend to move to `subscriptionPlacements`; each entry must target `platform`, `landing-zones`, or `sandbox`.

## Validate and deploy

Compile locally with the Bicep CLI. Compilation does not contact or modify Azure:

```sh
bicep build main.bicep
```

Azure-side validation requires an authenticated identity with permissions to create management groups, assign policy at the root management group, and move any listed subscriptions:

```sh
az login
az deployment tenant validate \
  --location uksouth \
  --template-file main.bicep \
  --parameters @parameters.example.json
```

Azure CLI accepts JSON parameter files. To use the Bicep parameters file, generate a JSON parameters file first:

```sh
bicep build-params main.bicepparam --outfile main.parameters.json
```

After reviewing the template and validation result, deploy with:

```sh
az deployment tenant create \
  --name landing-zone-baseline \
  --location uksouth \
  --template-file main.bicep \
  --parameters @parameters.example.json
```

Tenant-scope deployment can change governance, and subscription placement moves subscriptions from their current management-group parents. Review all parameter values and the target tenant before deployment. No live deployment has been run as part of this repository change.
