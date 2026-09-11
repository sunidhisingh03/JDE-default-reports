Connect-AzAccount -Identity

$script:data = @()

$allsubscriptions = Get-AzSubscription

foreach($subscriptions in $allsubscriptions){

   Set-AzContext -Subscription $subscriptions.Id

    $vms = Get-AzVM
    $startTime = (Get-Date).AddMonths(-1)
    $endTime = Get-Date

    foreach ($vm in $vms) {
        Write-Output "🔍 Processing VM: $($vm.Name)"
        $resourceId = $vm.Id
       

        # CPU Metrics
        $cpuMetricsMax = Get-AzMetric -ResourceId $resourceId `
            -MetricName "Percentage CPU" `
            -StartTime $startTime `
            -EndTime $endTime `
            -TimeGrain "01:00:00" `
            -AggregationType Maximum

       

        $cpuMax = ($cpuMetricsMax.Data | Measure-Object -Property Maximum -Maximum).Maximum
        if ($cpuMax -eq $null) { $cpuMax = 0 }



            $dataRow = [pscustomobject]@{
                "Subscription Name"         = $subscriptions.Name
                "VM Name"                   = $vm.Name
                "OS Type"                   = $vm.StorageProfile.OsDisk.OsType
                "VM Size"                   = $vm.HardwareProfile.VmSize
                "Resource Group"            = $vm.ResourceGroupName
                "Max CPU (%)"               = "{0:N2}" -f $cpuMax
               
            }

           
            $script:data+= $dataRow
    }
    
}
$csvPath = "cpu_utilization.csv"
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