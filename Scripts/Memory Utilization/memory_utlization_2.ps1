
Connect-AzAccount -Identity

$script:data = @()

$allsubscriptions = Get-AzSubscription

foreach($subscriptions in $allsubscriptions){

    Set-AzContext -Subscription $subscriptions.Id

    $vms = Get-AzVM
    $startTime = (Get-Date).AddMonths(-1)
    $endTime = Get-Date

    foreach ($vm in $vms) {
        Write-Output "Processing VM: $($vm.Name)"
        $resourceId = $vm.Id

        # ===== Memory Metrics =====
        # Existing: Max available % (unchanged)
        $memMetricsMax = Get-AzMetric -ResourceId $resourceId `
            -MetricName "Available Memory Percentage" `
            -StartTime $startTime `
            -EndTime $endTime `
            -TimeGrain "01:00:00" `
            -AggregationType Maximum

        $memMax = ($memMetricsMax.Data | Measure-Object -Property Maximum -Maximum).Maximum
        if ($memMax -eq $null) { $memMax = $null }  # keep null, avoid misleading 0

        # NEW (used only for Avg Used): Average available %
        $memMetricsAvg = Get-AzMetric -ResourceId $resourceId `
            -MetricName "Available Memory Percentage" `
            -StartTime $startTime `
            -EndTime $endTime `
            -TimeGrain "01:00:00" `
            -AggregationType Average

        # Compute average across datapoints where Average exists
        $avgAvailableRaw = ($memMetricsAvg.Data |
            Where-Object { $_.Average -ne $null } |
            Measure-Object -Property Average -Average).Average

        $avgAvailable = if ($avgAvailableRaw -ne $null) { [math]::Round([double]$avgAvailableRaw, 2) } else { $null }

        # The ONLY new output column:
        $avgUsed = if ($avgAvailable -ne $null) { [math]::Round(100 - $avgAvailable, 2) } else { $null }

        # Build the row — add ONLY "Avg Used Memory (%)"
        $dataRow = [pscustomobject]@{
            "Subscription Name"        = $subscriptions.Name
            "VM Name"                  = $vm.Name
            "OS Type"                  = $vm.StorageProfile.OsDisk.OsType
            "VM Size"                  = $vm.HardwareProfile.VmSize
            "Resource Group"           = $vm.ResourceGroupName
            "Max Available Memory (%)" = if ($memMax -ne $null) { "{0:N2}" -f $memMax } else { "" }
            "Avg Used Memory (%)"      = if ($avgUsed -ne $null) { "{0:N2}" -f $avgUsed } else { "" }
        }

        $script:data += $dataRow
    }
}

# ===== CSV output =====
$csvPath = "memory_utilization.csv"
$script:data | Export-Csv -Path $csvPath -Force -NoTypeInformation -Encoding UTF8

# Upload to Azure Storage using SPN with Storage Blob Data Contributor role
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($csvPath)
 
# Create storage context using connected account (SPN must have Storage Blob Data Contributor role)
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
 
# Upload the CSV file
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false
 
Write-Output "Resource report uploaded to Azure Storage container '$containerName' as '$blobName'."