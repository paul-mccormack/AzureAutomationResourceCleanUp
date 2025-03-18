targetScope = 'managementGroup'

param automationAccountId string
param roleDefinitionId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roleDefinitionId
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, roleDefinitionId, automationAccountId)
  properties: {
    principalId: automationAccountId
    roleDefinitionId: roleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

