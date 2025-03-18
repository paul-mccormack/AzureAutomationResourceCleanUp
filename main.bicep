//This template needs to be run at Management Group scope as we want to apply role assignments at that level.  Use the commands below to deploy.
//-ManagementGroupId should be the management group containing the subscription and resource group you are deploying resources into.

//Connect-AzAccount
//New-AzManagementGroupDeployment -ManagementGroupId MG-Management -Location UKSouth -TemplateFile .\main.bicep

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

@description('Required: Management Group ID where you want to give the managed identity contributor access')
param mgtGroupIam string

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

@description('Module for role assignment using output from deployResources module')
module roleAssignment 'modules/roleAssignment.bicep' = [ for roleDefinitionId in roleDefinitionIds: {
  scope: managementGroup(mgtGroupIam)
  name: 'roleAssignment-${roleDefinitionId}'
  params: {
    automationAccountId: deployResources.outputs.automationAccountPrincipalId
    roleDefinitionId: roleDefinitionId
  }
}]
