# Cleaning up orphaned resources using Azure Automation and Azure Resource Graph.

## Introduction

Resources in Azure can be left behind as other resources reach the end of their life and are deleted.  Some don't incur cost like Network Security Groups or NIC's. Other resources which are way too easy to be left behind do, for example Public IP addresses and VM disks.  In the case of VM disks that wasted cost could be considerable.

Advisor does alert you to orphaned disks but I wanted a method to catch the rest of the resources I've just mentioned.  My solution is to use an Automation Account to run Azure Resource Graph queries then tag the suspected orphaned resources for investigation.  Searching for the tag in the portal will list them with the date they were tagged in the value.

More resources could easily be added to the search criteria just by adding the necessary code to the PowerShell script in the runbook.

The deployment will be targetted at the top level management group using Bicep in a Deployment Stack, this allows us to take advantage of the role assignments being cleaned up automatically if the stack is deleted.  The resources can be deployed where ever in your environment is convenient by editing the deployment parameters.

> [!NOTE]
> Full details can be found in this post on [howdoyou.cloud](https://howdoyou.cloud/posts/finding-orphaned-azure-resources/)