#
# This is an alternative way of finding the subscriptions using Azure Resource Graph.  Not used in the deployment at the moment.

$subQuery = 'resourcecontainers
| where type == "microsoft.resources/subscriptions"
| mv-expand managementGroupParent = properties.managementGroupAncestorsChain
| where managementGroupParent.name =~ "Your top level MG ID"
| project name, subscriptionId'

$subs = Search-AzGraph -Query $subQuery