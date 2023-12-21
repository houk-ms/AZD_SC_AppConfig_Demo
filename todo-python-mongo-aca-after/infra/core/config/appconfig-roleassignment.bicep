param configStoreName string
param principalId string
param roleDefinitionId string = '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b' // data owner
param name string = guid(resourceGroup().id, configStoreName, principalId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: configStore
  name: name
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
  }
}


resource configStore 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: configStoreName
}
