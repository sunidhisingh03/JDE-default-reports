Connect-AzAccount -Identity
Function VMStatus {
    param()
    try {
        $vmData = @()
        $vms = Get-AzVM
        foreach ($vm in $vms) {
            if ($vm.ResourceGroupName -ne "pi0026") {
                $nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id
                $nic = Get-AzNetworkInterface -ResourceId $nicId
                $privateIp = $nic.IpConfigurations[0].PrivateIpAddress

                $vmInstanceView = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status

                $dataRow = [pscustomobject]@{
                    "Subscription Name" = (Get-AzContext).Subscription.Name
                    "Virtual Machine" = $vm.Name
                    "ResourceGroup" = $vm.ResourceGroupName
                    "Private Ip Address" = $privateIp
                    "State" = $vmInstanceView.Statuses | Where-Object { $_.Code -like "PowerState*" } | Select-Object -ExpandProperty DisplayStatus
                    "OS Type" = $vm.StorageProfile.OsDisk.OsType
                    "OS Name" = $vmInstanceView.OsName
                    "OS Version" = $vmInstanceView.OsVersion
                }

                $vmData += $dataRow
            }
        }

        $script:vmStatus += $vmData
    } catch {
        Write-Output "Error while fetching VM status - $($_.Exception.Message)"
    }
}

$script:vmStatus = @()

Write-Output "Fetching all subscriptions..."
$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Write-Output "Setting context to subscription $($subscription.Name)..."
    Set-AzContext -SubscriptionId $subscription.Id
    Write-Output "Fetching VM status for current subscription..."
    VMStatus
}

Write-Output "Creating CSV file for VMs Data..."
$vmStatus | Export-Csv -Path "Azure_VM_Inventory.csv" -NoTypeInformation -Encoding UTF8 -Force
$csvPath = "Azure_VM_Inventory.csv"

# Upload to Azure Storage using SPN with Storage Blob Data Contributor role
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($csvPath)
 
# Create storage context using connected account (SPN must have Storage Blob Data Contributor role)
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
 
# Upload the CSV file
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false
 
Write-Output "Resource report uploaded to Azure Storage container '$containerName' as '$blobName'."