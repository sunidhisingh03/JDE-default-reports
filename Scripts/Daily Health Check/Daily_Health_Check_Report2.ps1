Connect-AzAccount -Identity
Function ExpressRouteHealth{
     $d=$null
     $d=@()
     $ECData=Get-AzExpressRouteCircuit
     if($ECData){
          $tenantId     = "22d30701-ec5e-4bdc-ba4f-b9234053b0a9"
          $clientId     = "6d03f325-3ed5-498e-a298-86e7659c1c45"
          $clientSecret = Get-AutomationVariable -Name "client_secret_jde"
          $body = @{
              grant_type    = "client_credentials"
              client_id     = $clientId
              client_secret = $clientSecret
              scope         = "https://management.azure.com/.default"
        }
          $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $body
          $accessToken = $tokenResponse.access_token
          $authHeader = @{"Authorization" = "Bearer $accessToken";'Accept'='application/json'}
          $apiVersion = "2018-07-01"

          foreach($EC in $ECData)
            {
               $ID=$EC.Id
               $URI="https://management.azure.com/$($ID)/providers/Microsoft.ResourceHealth/availabilityStatuses"
               $URI = $URI + "?api-version=$apiVersion"
               $Response = Invoke-RestMethod -Method GET -Uri $URI -Headers $authHeader -ContentType "application/json"

               $Responses=$Response.value

               foreach($r in $Responses)
               {
                  if($r.properties.availabilityState)
                  {
                      $State=$r.properties.availabilityState
                      break
                  }
               }
                $data="
               <tr>
               <td>$($Subscription.Name)</td>
               <td>$($EC.Name)</td>
               <td>$($EC.ResourceGroupName)</td>
               <td>$($State)</td>
               </tr>"
               $d+=$data
                   <#Write-Host "----Start-----"
                   Write-Host $Subscription.Name
                   Write-Host $EC.Name
                   Write-Host $EC.ResourceGroupName
                   Write-Host $State
                   Write-Host "----Stop-----"#>
            }
            $script:ExpressRouteData+=$d
     }

}


Function ServiceHealth{
param()
try{
    
    $serviceHealthEvents = (Get-AzResource -ResourceType "Microsoft.ResourceHealth/events") | ?{$_.properties.Status -eq "Active"}
    #$healthData = $null
    #$healthData = @()
    #$script:healthData = @()
    $healthD = $null
    $healthD = @()
    
    if($serviceHealthEvents){
        
        foreach($event in $serviceHealthEvents){
            $a=get-date ($event.Properties.ImpactMitigationTime)
              $b=get-date
              if($a -ge $b){
            $dataRow = "
            </tr>
                <td>$($subscription.Name)</td>
                <td>$($event.Name)</td>
                <td>$($event.Properties.Title)</td>
                
                <td>$($event.Properties.Impact.ImpactedService)</td>
                <td>$($event.Properties.Impact.ImpactedRegions.ImpactedRegion)</td>
                <td>$(get-date ($event.Properties.ImpactMitigationTime) -Format "dd/MMM/yyyy hh:mm:ss")</td>
                <td>$($event.Properties.Status)</td>
                 <td>$(get-date ($event.Properties.LastUpdateTime) -Format "dd/MMM/yyyy hh:mm:ss")</td>
                <td>$($event.Properties.EventType)</td>
                <td>$($event.Properties.EventLevel)</td>
            </tr>"
            $healthD += $dataRow
            }
        }
    
        $script:healthData += $healthD
    }
    else{
        
        Write-Output "No Health Data found on $($subscription.Name)"
    }

}catch{
    
    $errorHealth = "Error while fetching to service health - $($error[0])"
    Write-Output $errorHealth 
}

}

Function StorageEgress{
param(
    
    $storageAccounts
)
try{
    
    $storageaccounts = Get-AzStorageAccount
    $sizeInBytes = 0
    $egressD = $null
    $egressD = @()
    
    
    if($storageAccounts){
        
        foreach($account in $storageAccounts){
        
            if($account.subscriptionId -eq $subscription.id){

                $fetchAccount = Get-AzStorageAccount -ResourceGroupName $account.resourceGroup -Name $account.Name     
                $MetricValues = Get-AzMetric -ResourceId $fetchAccount.Id -MetricName Egress -AggregationType Total -TimeGrain 12:00:00 -StartTime (Get-Date).AddDays(-1) -EndTime (Get-Date) 
                foreach($value in $MetricValues.Data){
            
                    $sizeInBytes += $value.Total
                }
                $sizeInMB = ([math]::Round(($sizeInBytes/1MB),2)).ToString() + " MB"

                $dataRow = "
                    </tr>
                        <td>$($subscription.Name)</td>
                        <td>$($account.name)</td>
                        <td>$($account.resourceGroup)</td>
                        <td>$($sizeInMB)</td>
                    </tr>"
                $egressD += $dataRow
            }

        }

        if($egressD){
            
            $script:egressData += $egressD
        }
    }
    else{
        
        Write-Output "Please provide storage account information from xml for atleast one subscription."
    }

}catch{

    $errorEgress = "Error while fetching egressData - $($error[0])"
    Write-Output $errorEgress 
}
}

Function UnattachedNics {
    try {
        $nicRows = @()
        $unattachedNics = Get-AzNetworkInterface | Where-Object {
            # Not attached to VM
            $_.VirtualMachine -eq $null -and
            # Not Private Endpoint NIC
            $_.PrivateEndpoint -eq $null -and
            $_.PrivateEndpointConnections.Count -eq 0 -and
            # Not Load Balancer
            ($_.IpConfigurations.BackendAddressPools.Count -eq 0) -and
            # Not App Gateway
            ($_.IpConfigurations.ApplicationGatewayBackendAddressPools.Count -eq 0) -and
            # Not associated with NSG
            $_.NetworkSecurityGroup -eq $null
        }
        if ($unattachedNics) {
            foreach ($nic in $unattachedNics) {
                $ipConfig = $nic.IpConfigurations[0]
                $allocationMethod = $ipConfig.PrivateIpAllocationMethod
                $ipAddress       = $ipConfig.PrivateIpAddress
                $isPrimary       = $ipConfig.Primary
    
                $publicIpValue = "None"
                if ($ipConfig.PublicIpAddress -and $ipConfig.PublicIpAddress.Id) {
                    try {
                        $pip = Get-AzPublicIpAddress -ResourceId $ipConfig.PublicIpAddress.Id -ErrorAction Stop
                        if ($pip.IpAddress) {
                            $publicIpValue = $pip.IpAddress
                        }
                    }
                    catch {
                        $publicIpValue = "Unavailable"
                    }
                }
                $dnsServers = if ($nic.DnsSettings.DnsServers) {
                    ($nic.DnsSettings.DnsServers -join ",")
                } else {
                    "None"
                }

                $row = @"
<tr>
<td>$($subscription.Name)</td>
<td>$($nic.Name)</td>
<td>$($nic.ResourceGroupName)</td>
<td>$allocationMethod</td>
<td>$ipAddress</td>
<td>$isPrimary</td>
<td>$publicIpValue</td>
<td>$dnsServers</td>
<td>$($nic.Location)</td>
<td>$($nic.Id)</td>
</tr>
"@
                $nicRows += $row

            }
            if ($nicRows.Count -gt 0) {
                $script:nicData += ($nicRows -join "`n")
            }
        }
    }

    catch {

        $script:nicData += "<tr><td colspan='10'>Error fetching unattached NICs - $($_)</td></tr>"

    }

}
  
 
Function GetStorageSyncGroups{
param()
try{
    
    $syncD = $null
    $syncD = @()
    #$storageSyncData = $null
    $getAllServices = Get-AzStorageSyncService

    if($getAllServices){

        foreach($service in $getAllServices){
        
            $getAllSyncGroups = Get-AzStorageSyncGroup -ResourceGroupName $service.ResourceGroupName -StorageSyncServiceName $service.StorageSyncServiceName

            foreach($syncgroup in $getAllSyncGroups){
            
                $serverEndpoint = Get-AzStorageSyncServerEndpoint -ResourceGroupName $service.ResourceGroupName -StorageSyncServiceName $service.StorageSyncServiceName -SyncGroupName $syncgroup.SyncGroupName
                foreach($endpoint in $serverEndpoint){
                    $dataRow = "
                    </tr>
                        <td>$($subscription.Name)</td>
                        <td>$($endpoint.StorageSyncServiceName)</td>
                        <td>$($endpoint.ResourceGroupName)</td>
                        <td>$($endpoint.SyncGroupName)</td>
                        <td>$($endpoint.ServerLocalPath)</td>
                        <td>$($endpoint.FriendlyName)</td>
                        <td>$($endpoint.SyncStatus.DownloadHealth)</td>
                        <td>$($endpoint.SyncStatus.UploadHealth)</td>
                    </tr>"           
                        $syncD += $dataRow 
                }
            }
        }

        if($syncD){
            
            $script:storageSyncData += $syncD
        }

     }
     else{
        
        Write-Output "Unable to find any storage service for subscription: $($subscription.Name)"
     }
}catch{
    
    $errorSync = "Error while fetching storage sync service - $($error[0])"
    Write-Output $errorSync
}

}

function Get-AzVMBackupStatus {

param(

)
try{
    
    #Get Recovery Vaults
    $results = $null
    $results = @()
    $totalSuccessful = 0
    $totalFailed = 0
    $totalInProgress = 0
    $vaults = Get-AzRecoveryServicesVault

    if($vaults){
        
        foreach($vault in $vaults){
    
            $vaultBackupJobs = Get-AzRecoveryServicesBackupJob -VaultId $vault.id -From (Get-Date).AddDays(-1).ToUniversalTime()
            foreach($job in $vaultBackupJobs){
        
                if($job.Status -eq "Completed"){
            
                    $totalSuccessful = $totalSuccessful + 1 
                }
        
                if($job.Status -eq "InProgress"){
            
                    $totalInProgress = $totalInProgress + 1 
                }

                if($job.Status -eq "Failed"){
            
                    $totalFailed = $totalFailed + 1 
                }

            }

        }

        $script:backupData += "
                </tr>
                        <td>$($subscription.Name)</td>
                        <td>$($vaults.Count)</td>
                        <td>$totalSuccessful</td>
                        <td>$totalInProgress</td>
                        <td>$totalFailed</td>
                        <td>$($totalSuccessful + $totalFailed + $totalInProgress)</td>
                 </tr>
        "
        
    }
    else{
        
        Write-Output "No recovery vaults for subscription - $($subscription.Name)"
        $script:backupData += "
                </tr>
                        <td>$($subscription.Name)</td>
                        <td>No recovery vaults for this subscription.</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                 </tr>
        "
    }
}
catch{
    
    $errorDeletion = "Error while fetching backup status: $($error[0])"
    Write-Output $errorDeletion
}

}

Function UnattachedDisks {
param()
try {
   $diskD = @()
  
   $unattachedDisks = Get-AzDisk | Where-Object {
       $_.ManagedBy -eq $null -and
       $_.DiskState -eq "Unattached"
   }
   if ($unattachedDisks) {
       foreach ($disk in $unattachedDisks) {
           $dataRow = @"
</tr>
<td>$($subscription.Name)</td>
<td>$($disk.Name)</td>
<td>$($disk.ResourceGroupName)</td>
<td>$($disk.Location)</td>
<td>$($disk.DiskSizeGB)</td>
<td>$($disk.Sku.Name)</td>
<td>$($disk.TimeCreated)</td>
<td>$($disk.DiskState)</td>
<td>$($disk.Id)</td>
</tr>
"@
           $diskD += $dataRow
       }
       if ($diskD) {
           $script:unattachedData += $diskD
       }
   }
   
}
catch {
   $script:unattachedData += "<tr><td colspan='9'>Error while fetching unattached disks - $($_)</td></tr>"
}
}
Function GetSnapshots {
param()
try {
   $snapshotData = $null
   $snapshot = @()
   $cutoffDate = (Get-Date).AddDays(-30)
   $allSnapshots = Get-AzSnapshot | Where-Object {
       $_.TimeCreated -lt $cutoffDate
   }
   if ($allSnapshots) {
       foreach ($snap in $allSnapshots) {
           $dataRow = @"
<tr>
<td>$($subscription.Name)</td>
<td>$($snap.Name)</td>
<td>$($snap.ResourceGroupName)</td>
<td>$($snap.DiskSizeGB)</td>
<td>$($snap.TimeCreated)</td>
<td>$($snap.Sku.Name)</td>
<td>$($snap.Incremental)</td>
<td>$($snap.Id)</td>
</tr>
"@
           $snapshot += $dataRow
       }
       if ($snapshot) {
           $script:snapshotData += $snapshot
       }
   }
   else {
       Write-Output "Unable to find snapshot data for current subscription - $($subscription.Name)"
   }
}
catch {
   $errorSnaps = "Error while fetching snapshots - $($_)"
   Write-Output $errorSnaps
}
}

Function EmptyRG{
try{
    
    $rgData = $null
    $rgData = @()

    $allResourceGroups = Get-AzResourceGroup 
    foreach($resourceGroup in $allResourceGroups){
    
        $emptyResourceGroupCheck = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
        if(!$emptyResourceGroupCheck){
        
            $datarow = "
                </tr>
                    <td>$($subscription.Name)</td>
                    <td>$($resourceGroup.ResourceGroupName)</td>
                    <td>$($resourceGroup.Location)</td>
                </tr>
            "
            $rgData += $datarow

        }
}

    if($rgData){
         $script:resourceGroupData += $rgData
    }
    #    $script:resourceGroupData += "
    #             </tr>
    #                 <td>$($subscription.Name)</td>
    #             </tr>
    #         "
    # }
    # else{
        
    #     $script:resourceGroupData += $rgData
    #  }

}catch{
    
    $errorRG = "Error while fetching empty resource groups - $($error[0])"
    Write-Output $errorRG
}
}

Function HTMLReport{
param()

try{

$htmlReport = $null
if(!$healthData){
    
    $healthData = "
            </tr>
                <td>NA</td>
                <td>This feature is disabled for now.</td>
                <td>NA</td>
                <td>NA</td>
                <td>NA</td>
                <td>NA</td>
                <td>NA</td>
                <td>NA</td>
                <td>NA</td>
                <td>NA</td>
            </tr>"

}

if(!$egressData){
    
    $egressData = "
            </tr>
 <td>This feature is disabled for now.</td>
                <td>NA</td>
                <td>NA</td>
                <td>NA</td>
            </tr>"

}

if(!$ngwData){
    
    $ngwData = "
                </tr>
                    <td>NA</td>
                    <td>This feature is disabled for now.</td>
                    <td>NA</td>
                    <td>NA</td>
                    <td>NA</td>
                    <td>NA</td>
                    <td>NA</td>
                </tr>"
}

if(!$storageSyncData){
    
               $storageSyncData = "
                    </tr>
                        <td>NA</td>
                        <td>There are no storage sync service deployed..</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                    </tr>" 
}
if(!$unattachedData){
    
    $unattachedData +="
                    </tr>
                        <td>NA</td>
                        <td>There are no unattached disks.</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                    </tr>" 
}



if(!$snapshotData){
    
    $snapshotData += "
                </tr>
                    <td>NA</td>
                    <td>There are no snapshots created in last seven days.</td>
                    <td>NA</td>
                    <td>NA</td>
                    <td>NA</td>
                    <td>NA</td>
                    <td>NA</td>
                    <td>NA</td>
                </tr>"
}
if(!$nicData){

    $nicData += "
                </tr>
                        <td>NA</td>
                        <td>This feature is disabled for now.</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                        <td>NA</td>
                 </tr>
        "
}

if(!$resourceGroupData){

    $resourceGroupData += "
                </tr>
                        <td>NA</td>
                        <td>This feature is disabled for now.</td>
                        <td>NA</td>
                 </tr>
        "
}


$script:htmlReport = @"
    <html>
    <head>
        <style>{font-family: Arial; font-size: 10pt;}
            TABLE{border: 1px solid black; border-collapse: collapse; font-size:13pt;width: 100%;}
            TH{border: 1px solid black; font-size: 10pt;background-color: Cadetblue; padding: 5px; color: white;}
            TD{border: 1px solid black; font-size: 10pt;padding: 5px; }
            body{background-color: Azure;}
            h2{background-color: Cadetblue; color: white;text-align: center;}
            p{background-color: Azure;}
            h3{background-color: Cadetblue; color: white;text-align: center;}
        </style>
    </head>
    <body>
                <h2>Active Health Events</h2>
<table>
                <tr><th>Subscription Name</th><th>Event Name</th><th>Title</th><th>Impacted Service</th><th>Impacted Region</th><th>Impact Mitigation Time</th><th>Status</th><th>Last Update Time</th><th>Event Type</th><th>Event Level</th>
                </tr>
                $healthData
                </table>
                <h2>Daily Network Gateway </h2>
                <table>
                <tr><th>Subscription Name</th><th>Network Gateway</th><th>Resource Group</th><th>Availability State</th><th>Summary</th><th>Reason Type</th><th>Reported Time</th>
                </tr>
                $ngwData
                </table>
                <h2>Storage Sync Service</h2>
                <table>
                  <tr><th>Subscription Name</th><th>Storage Sync Service</th><th>Resource Group Name</th><th>Storage Sync Group</th><th>Server Local Path</th><th>Server</th><th>Download Health</th><th>Upload Health</th>
                </tr>
                $storageSyncData
                </table>

                <h2>ExpressRoute Resource </h2>
                <table>
                <tr><th>Subscription Name</th><th>Name</th><th>Resource Group</th><th>Resource Health</th>
                </tr>
                $script:ExpressRouteData
                </table>

                <h2>Daily Unattached Disks </h2>
                <table>
                <tr><th>Subscription Name</th><th>Disk Name</th><th>Resource Group</th><th>Location</th><th>Disk SizeGB</th><th>Sku Name</th><th>Time Created</th><th>Disk State</th><th>Disk Id</th>
                $unattachedData
</table>
                <h2>Snapshots Older than 30 days </h2>
                <table>
                <tr><th>Subscription Name</th><th>Snapshot Name</th><th>Resource Group</th><th>Size</th><th>Time Created</th><th>Disk State</th><th>SKU Name</th><th>Incremental</th>
                </tr>
                $snapshotData
                </table>
                <h2>Unattached NIC</h2>
                <table>
                <tr><th>Subscription Name</th><th>Network Interface</th><th>Resource Group</th><th>Allocation Method</th><th>IP Address</th><th>Primary</th><th>Public IP</th><th>DNS Servers</th><th>Location</th><th>NIC Id</th>
                </tr>
                $nicData
                </table>
                <h2>Empty Resource Groups </h2>
                <table>
                <tr><th>Subscription Name</th><th>Resource Group Name</th><th>Location</th>
                </tr>
                $resourceGroupData
                </table>
                <h3>Developed By - Elastic Ops Autonomics</h3>
    </body>
    </html>
"@

}catch{
    
    $errorHTML = "Error while creating HTML report - $($error[0])"
    Write-Output $errorHTML "85"
}

}

#get all storage accounts
$allStorageAccounts = $inputLogFile.AzureConfig.StorageAccounts.StorageAccount

#declare html variables
$script:healthData = @()
$script:egressData = @()
$script:ngwData = @()
$script:storageSyncData = @()
$script:unattachedData = @()
$script:backupData = @()
$script:snapshotData = @()
$script:nicData = @()
$script:resourceGroupData = @()
$script:ExpressRouteData=@()
#endregion

#Get All Subscriptions 

write-Output "Fetching all subscriptions available..." 
$allSubscriptions = Get-AzSubscription 

if($allSubscriptions){
    
    
    foreach($subscription in $allSubscriptions){
        
        Write-Output "Setting Context to $($subscription.Name)"
        Set-AzContext -Subscription $subscription.Id
        
        Write-Output "Fetching Service Health Events..."
        ServiceHealth 
        
        #AddtoLogfile "Fetching Top 5 Storage accounts with most egress data size..."
        #StorageEgress -storageAccounts $allStorageAccounts    

        #Write-Output "Fetching network gateway health..."
        #NetworkGateway

        Write-Output "Fetching storage sync service data..."
        GetStorageSyncGroups

        #AddtoLogfile "Fetching Backup Jobs data..."
       # Get-AzVMBackupStatus

        Write-Output "Fetching ExpressRoute Circuits Resource Health..."
        ExpressRouteHealth
        
        Write-Output "Fetching Unattached disks data..."
        UnattachedDisks

        Write-Output "Fetching Snapshots data..."
        GetSnapshots
        
        Write-Output "Fetching unattached Nics..."
        UnattachedNics

        Write-Output "Fetching empty resource groups..."
        EmptyRG
    }
}

Write-Output "Creating HTML Report"
HTMLReport
$htmlReport | Out-File "DailyHealthCheck.html"


$fileName = "DailyHealthCheck.html"
# Upload to Azure Storage using SPN with Storage Blob Data Contributor role
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($fileName)
 
# Create storage context using connected account (SPN must have Storage Blob Data Contributor role)
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
 
# Upload the CSV file
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false
 
Write-Output "Resource report uploaded to Azure Storage container '$containerName' as '$blobName'."