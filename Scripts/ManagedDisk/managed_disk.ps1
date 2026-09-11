Connect-AzAccount -Identity
  
Function ManagedDisks{
param()
try{    
    $diskData = @()
    $manageddisks = Get-AzDisk
    
    foreach($disk in $manageddisks){
        Write-Output $disk.Name
        if($disk.managedBy){
        
            $attachedTo = ($disk.managedby -split "/")[-1]
        }
        else{       
            $attachedTo = "Unattached"
        }

    $dataRow = [pscustomobject]@{
    "Subscription Name"     = $Subscription.Name
    "Disk Name"             = $disk.Name
    "Resource Group"        = $disk.ResourceGroupName
    "Location"              = $disk.Location
    "Attached To"           = $attachedTo
    "SKU"                   = $disk.Sku.Name
    "Size (GB)"             = $disk.DiskSizeGB
    "Time Created"          = $disk.TimeCreated
    "Disk State"            = $disk.DiskState
    "Script Execution Date" = (Get-Date -Format "dd-MMM-yyyy")
  }
        $diskData += $dataRow
    }
    $script:diskDataReport += $diskData
}catch{
    
    Write-Output "Error while fetching managed disks - $($error[0])"
}
}
$script:diskDataReport = @()
$subscriptions = Get-AzSubscription
foreach($subscription in $subscriptions){
            
            Write-Output "Setting context to subscription $($subscription.Name)..."
            Set-AzContext -Subscription $subscription.Id
 
            Write-Output "Fetching managed disks for current subscription..."
            ManagedDisks
}

$csvPath = "Azure_Managed_Disks.csv"
$script:diskDataReport | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Force

# Upload to Azure Storage using SPN with Storage Blob Data Contributor role
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($csvPath)
 
# Create storage context using connected account (SPN must have Storage Blob Data Contributor role)
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
 
# Upload the CSV file
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false
 
Write-Output "Resource report uploaded to Azure Storage container '$containerName' as '$blobName'."