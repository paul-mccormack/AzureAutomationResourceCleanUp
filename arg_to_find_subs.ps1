$mgroupQuery = 'resourcecontainers
| where type == "microsoft.resources/subscriptions"
| mv-expand managementGroupParent = properties.managementGroupAncestorsChain
| where managementGroupParent.name =~ "MG-SCC-Common"
| project name, subscriptionId'

$mgroups = Search-AzGraph -Query $mgroupQuery