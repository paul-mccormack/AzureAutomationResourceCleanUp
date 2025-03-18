//This template needs to be run at Management Group scope as we want to apply role assignments at that level.  Use the commands below to deploy.
//-ManagementGroupId should be the management group containing the subscription and resource group you are deploying resources into.

//Connect-AzAccount
//New-AzManagementGroupDeployment -ManagementGroupId MG-Management -Location UKSouth -TemplateFile .\main.bicep

targetScope = 'managementGroup'

@description('SubscriptionId that you are deploying resources into')
param subId string = 'subId'

@description('Resource Group name you are deploying resources into')
param resourceRgName string = 'rg-uks-mgmt-automation'

@description('Location of Resource Group')
param location string = 'UKSouth'

@description('Management Group ID where you want to give the managed identity contributor access')
param mgtGroupIam string = 'MG-SCC-Common'

@description('builtin role definition ID for Reader and Tag Contributor Roles')
param roleDefinitionIds array = [
  'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  '4a9ae827-6dc8-4573-8ac7-8239d42aa03f'
]
@description('Name for Automation Account')
param automationAccountName string = 'orphanedResourceTag'

@description('Name for Run Book')
param runbookName string = 'findOrphanedResources'

@description('Name for schedule')
param scheduleName string = 'dailySchedule'

@description('Schedule frequency')
@allowed([
  'Day'
  'Hour'
  'Minute'
  'Month'
  'OneTime'
  'Week'
])
param scheduleFrequency string = 'Day'

@description('Start time for schedule.  Set this to at least 15 minutes after the time you are deploying')
param startTime string = '2025-03-19T09:00:00.000Z'

@description('Location to pull the powershell script from')
param scriptUri string = 'https://raw.githubusercontent.com/paul-mccormack/AzureAutomationResourceCleanUp/refs/heads/main/tagOrphanResources.ps1'

@description('Tags')
param tags object = {
  'Created by': 'Paul McCormack'
  'Management Area': 'DDaT'
  Service: 'Azure Automation'
  'Cost Centre': 'Shared'
}

@description('Module for resource deployment')
module deployResources 'modules/resources.bicep' = {
  scope: resourceGroup(subId, resourceRgName)
  name: 'resourceDeployment'
  params: {
    location: location
    tags: tags
    automationAccountName: automationAccountName
    runbookName: runbookName
    scheduleName: scheduleName
    scheduleFrequency: scheduleFrequency
    startTime: startTime
    scriptUri: scriptUri
  }
}

@description('Module for role assignment using output from deployResources module')
module roleAssignment 'modules/roleAssignment.bicep' = [ for roleDefinitionId in roleDefinitionIds: {
  scope: managementGroup(mgtGroupIam)
  name: 'roleAssignment-${roleDefinitionId}'
  params: {
    automationAccountId: deployResources.outputs.automationAccountPrincipalId
    roleDefinitionId: roleDefinitionId
  }
}]
