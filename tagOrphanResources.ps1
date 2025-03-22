# Script prepared by Paul McCormack.

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null;

# Set the top level Management Group containing the management groups and subscriptions to scan
$ManagementGroupID = 'Your MG name'

# Get the date and time of the current run
$date = Get-Date

# Set the tag to be written
$tag = @{"Orphaned Resource" = "$date"}

# Azure Resource Graph query to find NSG's which are not attached to a NIC or a subnet and haven't been previously identified.
$orphanedNsgQuery = 'Resources
| where type == "microsoft.network/networksecuritygroups"
| where isnull(properties.networkInterfaces)
| where isnull(properties.subnets)
| where tags !contains "Orphaned Resource"
| project id, name'

# Azure Resource Graph query to find Disks which are not attached to a VM and haven't been previously identified.
$orphanedDiskQuery = 'Resources
| where type has "microsoft.compute/disks"
| extend diskState = tostring(properties.diskState)
| where managedBy == "" or diskState == "Unattached" and  diskState != "ActiveSAS"
| where tags !contains "Orphaned Resource"
| project resourceGroup, name, id, diskState, location, subscriptionId'

# Azure Resource Graph query to find NIC's which are not attached to a VM or a private endpoint and haven't been previously identified.
$orphanedNicQuery = 'Resources
| where type has "microsoft.network/networkinterfaces"
| where properties !has "privateLinkConnectionProperties"
| where properties !has "virtualmachine"
| where tags !contains "Orphaned Resource"
| project resourceGroup, name, id'

# Azure Resource Graph query to find public IP's which are not connected to a resource and haven't been previously identified.
$orphanedPublicIp = 'Resources
| where type contains "publicIPAddresses" and isnotempty(properties.ipAddress)
| where properties !has "ipConfiguration"
| where properties !has "natGateway"
| where tags !contains "Orphaned Resource"
| project resourceGroup, name, id'

# Import Az.ResourceGraph module
Import-Module Az.ResourceGraph

# Login to Azure using a Managed Service Identity
Connect-AzAccount -Identity

# Get the subscription IDs under the specified management group AND child management groups
function Get-AzSubscriptionsFromManagementGroup {
    param($ManagementGroupName)
    $mg = Get-AzManagementGroup -GroupId $ManagementGroupName -Expand
    foreach ($child in $mg.Children) {
        if ($child.Type -match '/managementGroups$') {
            Get-AzSubscriptionsFromManagementGroup -ManagementGroupName $child.Name
        }
        else {
            $child | Select-Object @{N = 'Name'; E = { $_.DisplayName } }, @{N = 'Id'; E = { $_.Name } }
        }
    }
}

# Get all Subscriptions under specified management group
$subIds = Get-AzSubscriptionsFromManagementGroup -ManagementGroupName $ManagementGroupID


foreach ($subId in $subIds) {

    # Switch context to the current subscription
    Set-AzContext -Subscription $subId.Id

    # Run the NSG query and store results
    $nsgs = Search-AzGraph -Query $orphanedNsgQuery
    
    # Create the tag on any NSG's identified
    if (!$nsgs) {
        Write-Output "No orphaned NSG's found on $date"
    }
    else {
        foreach ($nsg in $nsgs) {
            Write-Output "$($nsg.name) appears to be orphaned.  Tagging for investigation on $date"
            Update-AzTag -ResourceId $nsg.id -Tag $tag -Operation Merge
        }
    }
    
    # Run the disk query and store results
    $disks = Search-AzGraph -Query $orphanedDiskQuery
    
    # Create the tag on any disks identified
    if (!$disks) {
        Write-Output "No orphaned disks found on $date"
    }
    else {
        foreach ($disk in $disks) {
            Write-Output "$($disk.name) appears to be orphaned.  Tagging for investigation on $date"
            Update-AzTag -ResourceId $disk.id -Tag $tag -Operation Merge
        }
    }
    
    # Run the NIC query and store results
    $nics = Search-AzGraph -Query $orphanedNicQuery
    
    # Create the tag on any nics identified
    if (!$nics) {
        Write-Output "No orphaned nics found on $date"
    }
    else {
        foreach ($nic in $nics) {
            Write-Output "$($nic.name) appears to be orphaned.  Tagging for investigation on $date"
            Update-AzTag -ResourceId $nic.id -Tag $tag -Operation Merge
        }
    }
    
    # Run the public IP query and store results
    $pips = Search-AzGraph -Query $orphanedPublicIp
    
    # Create the tag on any public IP's identified
    if (!$pips) {
        Write-Output "No orphaned public ip's found on $date"
    }
    else {
        foreach ($pip in $pips) {
            Write-Output "$($pip.name) appears to be orphaned.  Tagging for investigation on $date"
            Update-AzTag -ResourceId $pip.id -Tag $tag -Operation Merge
        }
    }
}