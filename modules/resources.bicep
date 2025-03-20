param location string = resourceGroup().location
param tags object
param automationAccountName string
param runbookName string
param runbookDescription string
param runbookType string
param scriptUri string
param scheduleName string
param scheduleFrequency string
param startTime string

resource automation 'Microsoft.Automation/automationAccounts@2023-11-01' = {
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

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automation
  name: runbookName
  tags: tags
  location: location
    properties: {
    runbookType: runbookType
    description: runbookDescription
    publishContentLink: {
      uri: scriptUri
      version: '1.0'
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  name: scheduleName
  parent: automation
  properties: {
    frequency: scheduleFrequency
    startTime: startTime
    interval: any(1)
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
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
