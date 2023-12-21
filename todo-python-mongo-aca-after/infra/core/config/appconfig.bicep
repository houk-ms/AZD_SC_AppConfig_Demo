metadata description = 'Creates an App Configuration.'
param name string
param location string = resourceGroup().location
param tags object = {}

resource configStore 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'standard'
  }
}

output endpoint string = configStore.properties.endpoint
output name string = configStore.name
