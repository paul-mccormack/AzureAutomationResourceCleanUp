// Template prepared by Paul McCormack
//
// Deployment will use stacks to ensure role assignments are managed with the resources.
//
// This template needs to be run at Management Group scope as we want to apply role assignments at that level.  Use the commands below to deploy.
//
// Connect-AzAccount
// New-AzManagementGroupDeploymentStack -Name orphanedResourceScanDeployment -ManagementGroupId MG-SCC-Common -Location UKSouth -TemplateFile .\main.bicep -TemplateParameterFile .\main.bicepparam -ActionOnUnmanage deleteResources -DenySettingsMode None
// -ManagementGroupId should be the management group containing the subscription and resource group you are deploying resources into.
//
// Type Definitions
//

@description('Required: Run Book Type')
type runbookConfigType = 'Graph' | 'GraphPowerShell' | 'GraphPowerShellWorkflow' | 'PowerShell' | 'PowerShell72' | 'PowerShellWorkflow' | 'Python' | 'Python2' | 'Python3' | 'Script'

@description('Required: Schedule frequency')
type scheduleFrequencyType = 'OneTime' | 'Minute' | 'Hour' | 'Day' | 'Week' | 'Month'

//
// Deployment Scope
//

targetScope = 'managementGroup'

//
// Parameters
//

@description('Required: SubscriptionId that you are deploying resources into')
param subId string

@description('Required: Resource Group name you are deploying resources into')
param resourceRgName string

@description('Required: Location of Resource Group')
param location string

@description('Required: builtin role definition ID for Reader and Tag Contributor Roles')
param roleDefinitionIds array

@description('Required: Name for Automation Account')
param automationAccountName string

@description('Required: Name for Run Book')
param runbookName string

@description('Required: Set the runbook type')
param runbookType runbookConfigType

@description('Required: Run book description')
param runbookDescription string

@description('Required: Name for schedule')
param scheduleName string

@description('Required: Schedule frequency')
param scheduleFrequency scheduleFrequencyType

@description('Required: Start time for schedule.  Set this to at least 15 minutes after the time you are deploying')
param startTime string

@description('Required: URI to pull the powershell script')
param scriptUri string

@description('Required: Tags')
param tags object

//
// Resources
//

@description('Module for resource deployment')
module deployResources 'modules/resources.bicep' = {
  scope: resourceGroup(subId, resourceRgName)
  name: 'resourceDeployment'
  params: {
    location: location
    tags: tags
    automationAccountName: automationAccountName
    runbookName: runbookName
    runbookDescription: runbookDescription
    runbookType: runbookType
    scheduleName: scheduleName
    scheduleFrequency: scheduleFrequency
    startTime: startTime
    scriptUri: scriptUri
  }
}

@description('Create role assignments for automation account identity')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [ for roledefinitionId in roleDefinitionIds: {
  name: guid(managementGroup().id, roledefinitionId)
  properties: {
    principalId: deployResources.outputs.automationAccountPrincipalId
    roleDefinitionId: managementGroupResourceId('Microsoft.Authorization/roleDefinitions', roledefinitionId)
    principalType: 'ServicePrincipal'
  }
}]
