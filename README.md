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

The PowerShell script, which can be found  here, [tagOrphanedResources.ps1](https://github.com/paul-mccormack/AzureAutomationResourceCleanUp/blob/main/tagOrphanResources.ps1), is also very simple.  Set the tag key to use, get the current date and time for the tag value, setup the resource graph queries then loop through the results and set the tag on any resources it finds.  I considered putting the loop into a function to prevent just repeating the same loop but decided against it for the sake of keep ing the run book logs nice and clear.  particularly when it doesn't find any type of resource I am looking for.  I want it to say "No NSG's were found" and "No disks were found" instead repeating "No resources were found".  Maybe I'll revisit that at some point.

Setting up the resource graph queries to find orphaned resources involved creating a resource of that type then comparing the properties to the same type of resource which was in use.

For example.  The NSG query looks looks like the KQL below

```
$orphanedNsgQuery = 'Resources
| where type == "microsoft.network/networksecuritygroups"
| where isnull(properties.networkInterfaces)
| where isnull(properties.subnets)
| where tags !contains "Orphaned Resource"
| project id, name'
```

An NSG can be attached to a Subnet or a NIC.  not attached to anything the properties doesn't contain `properties.networkInterfaces` or `properties.subnets`.  To prevent already identified resources being found again on the next run and the date value of the tag being overwritten I have included a check to filter out already tagged resource with the line `| where tags !contains "Orphaned Resource"`.


