param location string = resourceGroup().location
param tags object
param automationAccountName string
param runbookName string
param scriptUri string
param scheduleName string
param scheduleFrequency string
param startTime string

resource automation 'Microsoft.Automation/automationAccounts@2024-10-23' = {
  name: automationAccountName
  tags: tags
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2024-10-23' = {
  parent: automation
  name: runbookName
  tags: tags
  location: location
    properties: {
    runbookType: 'PowerShell'
    description: 'Scan all deployed resources and tag with the email address of the last person who modified'
    publishContentLink: {
      uri: scriptUri
      version: '1.0'
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2024-10-23' = {
  name: scheduleName
  parent: automation
  properties: {
    frequency: scheduleFrequency
    startTime: startTime
    interval: any(1)
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2024-10-23' = {
  name: guid(resourceGroup().id, schedule.id)
  parent:automation
  properties: {
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: schedule.name
    }
  }
}

output automationAccountPrincipalId string = automation.identity.principalId
