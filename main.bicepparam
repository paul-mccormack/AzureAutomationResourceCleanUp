using './main.bicep'

param subId = 'sub id'
param resourceRgName = 'rg id'
param location = 'uksouth'
param roleDefinitionIds = [
  'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  '4a9ae827-6dc8-4573-8ac7-8239d42aa03f'
]
param automationAccountName = 'orphanedResourceTag'
param runbookName = 'findOrphanedResources'
param runbookDescription = 'Scan environment for orphaned resources and sets a tag for further investigation'
param runbookType = 'PowerShell'
param scheduleName = 'dailySchedule'
param scheduleFrequency = 'Day'
param startTime = '2025-03-21T09:30:00.000Z'
param scriptUri = 'https://raw.githubusercontent.com/paul-mccormack/AzureAutomationResourceCleanUp/refs/heads/main/tagOrphanResources.ps1'
param tags = {
  'Created by': 'Paul McCormack'
  'Management Area': 'DDaT'
  Service: 'Azure Automation'
  'Cost Centre': 'Shared'
}

