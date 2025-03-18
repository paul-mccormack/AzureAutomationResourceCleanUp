# Cleaning up orphaned resources using Azure Automation and Azure Resource Graph.

## Introduction

Resources in Azure can be left behind as other resources reach the end of their life and are deleted.  Some don't incur cost like Network Security Groups or NIC's but some do, for example Public IP addresses and VM disks.  In the case of VM disks the wasted cost could be considerable.

Advisor does alert you to orphaned disks but I wanted a method to catch the rest of the resources I've just mentioned.  My solution is to use an Automation Account to run Azure Resource Graph queries then tag the suspected orphaned resources for investigation.  Searching for the tag in the portal will list them with the date they were tagged in the value.

More resources could easily be added to the search just by ammending the PowerShell script in the runbook.

The resources will be deployed at the top level management group using Bicep in a Deployment Stack, this allows us to take advantage of the role assignments being cleaned up automatically if the stack is deleted.

## Deployment details

The deployment is very simple.  Consisting of an Automation Account and associated schedule to run a job daily at 9:30am.  The system assigned identity is then given two role assignments at the top level management group.  These are Reader and Tag Contributor.

As the deployment is scoped to a management group the resources are deployed using a module scoped to the target resource group.  See [main.bicep](https://github.com/paul-mccormack/AzureAutomationResourceCleanUp/blob/main/main.bicep) for the Bicep Template being used.

To deploy the template use the following command:

```bicep
New-AzManagementGroupDeploymentStack -ManagementGroupId MG-SCC-Common -Location UKSouth -TemplateFile .\main.bicep -TemplateParameterFile .\main.bicepparam -ActionOnUnmanage deleteResources -DenySettingsMode None
```

## Runbook PowerShell Script
