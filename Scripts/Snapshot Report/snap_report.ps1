Connect-AzAccount -Identity
 
# ---- All resource variables (init BEFORE function) ----
$Script:snapshotsdata1 = @()
$Script:snapshotsdata  = @()
 
# Function to collect snapshot data
Function Snapshotdata{
    param()
 
    try{
        # Get all snapshots in current context
        $snapshots = Get-AzSnapshot
 
        foreach($snapshot in $snapshots){
 
            # Default CreatedBy to blank
            $createdBy = ""
 
            # Activity Log is only retained for 90 days -> guard the query
            # (prevents errors for older snapshots)  [Microsoft docs]
            # https://learn.microsoft.com/en-us/azure/azure-monitor/platform/activity-log
            $start = [datetime]$snapshot.TimeCreated
            $end   = $start.AddHours(1)
            $ninetyDaysAgo = (Get-Date).AddDays(-90)
 
            if ($start -ge $ninetyDaysAgo) {
                # Try Az.Monitor 'Activity Log' first; fall back to Get-AzLog for compatibility
                try {
                    $d = Get-AzActivityLog -ResourceId $snapshot.Id -StartTime $start -EndTime $end -MaxRecord 100 -ErrorAction SilentlyContinue
                    if (-not $d) {
                        $d = Get-AzLog -ResourceId $snapshot.Id -StartTime $start -EndTime $end -MaxRecord 100 -ErrorAction SilentlyContinue
                    }
                    if ($d) { $createdBy = ($d.Caller | Select-Object -Last 1) }
                } catch {
                    # Leave CreatedBy empty if logs unavailable
                    $createdBy = ""
                }
            }
 
            # ---- Build HTML row using REAL tags (NOT &lt;...&gt;) ----
            $data = "
                <tr>
                    <td>$($subscription.Name)</td>
                    <td>$($snapshot.Name)</td>
                    <td>$($snapshot.ResourceGroupName)</td>
                    <td>$($snapshot.Location)</td>
                    <td>$($snapshot.Sku.Name)</td>
                    <td>$($snapshot.DiskSizeGB)</td>
                    <td>$($snapshot.TimeCreated)</td>
                    <td>$($createdBy)</td>
                </tr>"
 
            # ---- Build CSV row (keep your original columns/labels) ----
            $dataRow = [pscustomobject]@{
                "Subscription"            = $subscription.Name
                "Snapshot Name"           = $snapshot.Name
                "Snapshot ResourceGroup"  = $snapshot.ResourceGroupName
                "Location"                = $snapshot.Location
                "SKU"                     = $snapshot.Sku.Name
                "Disk Size(GB)"           = $snapshot.DiskSizeGB
                "TimeCreated"             = $snapshot.TimeCreated
                "Created BY"              = $createdBy
            }
 
            # Append to script-scoped collectors
            $Script:snapshotsdata1 += $dataRow
            $Script:snapshotsdata  += $data
        }
    }catch{
        Write-Output "Error while fetching Snapshots - $($_.Exception.Message)" "85"
    }
}
 
# ---- Iterate subscriptions with proper context ----
$subscriptions = Get-AzSubscription
 
foreach($subscription in $subscriptions){
    Write-Output "Setting context to subscription $($subscription.Name)..."
    Set-AzContext -Subscription $subscription.Id
 
    Write-Output "Fetching Snapshot data......"
    Snapshotdata
}
 
# ---- CSV output ----
Write-Output "Sending data to CSV file..."
$Script:snapshotsdata1 | Export-Csv -Path "Azure_Snapshots.csv" -Force -NoTypeInformation -Encoding UTF8
  
$fileName = "Azure_Snapshots.csv"

# Upload to Azure Storage using SPN with Storage Blob Data Contributor role
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($fileName)
 
# Create storage context using connected account (SPN must have Storage Blob Data Contributor role)
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
 
# Upload the CSV file
Set-AzStorageBlobContent -File $fileName -Container $containerName -Blob $blobName -Context $ctxSet-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false 
Write-Output "Resource report uploaded to Azure Storage container '$containerName' as '$blobName'."