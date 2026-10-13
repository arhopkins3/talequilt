// Static Web Apps, free tier, for the React build. Deployed from the Deploy workflow with a deployment token
// read at run time, never stored in the repository. Built-in authentication and the route rules that require
// an invited user live in src/web/staticwebapp.config.json (ADR 0008 stopgap).
param name string
param tags object
// Static Web Apps is a global service deployed to a handful of regions; westeurope is the nearest to UK South.
param location string = 'westeurope'

resource site 'Microsoft.Web/staticSites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Free', tier: 'Free' }
  properties: {
    stagingEnvironmentPolicy: 'Disabled'
    allowConfigFileUpdates: true
  }
}

output name string = site.name
output defaultHostname string = site.properties.defaultHostname
