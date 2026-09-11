# PowerShell script to fetch All Resources Report
Connect-AzAccount -Identity
$script:resourceData = @()
$subscriptions = Get-AzSubscription
 
foreach ($subscription in $subscriptions) {
    Set-AzContext -Subscription $subscription.Id
 
    try {
        $allResources = Get-AzResource
        $resourceD = @()
 
        foreach ($resource in $allResources) {
            $dataRow = [pscustomobject]@{
                "Subscription Name"   = $subscription.Name
                "Resource Name"       = $resource.Name
                "Resource Group Name" = $resource.ResourceGroupName
                "Resource Type"       = $resource.ResourceType
                "Location"            = $resource.Location
                "Resource Id"         = $resource.ResourceId
            }
            $resourceD += $dataRow
        }
 
        $script:resourceData += $resourceD
    } catch {
        Write-Output "Error while fetching resources for subscription $($subscription.Name): $($_.Exception.Message)"
    }
}
 
# Export to CSV
$csvPath = "Azure_All_Resources.csv"
$script:resourceData | Export-Csv -Path $csvPath -Force -NoTypeInformation -Encoding UTF8
  
# Upload to Azure Storage using SPN with Storage Blob Data Contributor role
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($csvPath)
 
# Create storage context using connected account (SPN must have Storage Blob Data Contributor role)
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
 
# Upload the CSV file
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false
 
Write-Output "Resource report uploaded to Azure Storage container '$containerName' as '$blobName'."