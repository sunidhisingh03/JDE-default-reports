Connect-AzAccount -Identity

# Authenticate and get token
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
 
$headers = @{
    Authorization = "Bearer $accessToken"
    ContentType   = "application/json"
}
 
# Get all subscriptions
$subscriptions = Get-AzSubscription
 
# Prepare output array
$vaultUsageData = @()
 
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id
 
    $vaults = Get-AzRecoveryServicesVault
 
    foreach ($vault in $vaults) {
        $vaultName = $vault.Name
        $resourceGroup = $vault.ResourceGroupName
        $subscriptionId = $sub.Id
        $subscriptionName = $sub.Name
 
        $url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.RecoveryServices/vaults/$vaultName/usages?api-version=2023-02-01"
 
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
 
            $grs   = [math]::Round((($response.value | Where-Object { $_.name.value -eq "GRSStorageUsage" }).currentValue / 1GB), 2)
            $lrs   = [math]::Round((($response.value | Where-Object { $_.name.value -eq "LRSStorageUsage" }).currentValue / 1GB), 2)
            $zrs   = [math]::Round((($response.value | Where-Object { $_.name.value -eq "ZRSStorageUsage" }).currentValue / 1GB), 2)
            $gzrs  = [math]::Round((($response.value | Where-Object { $_.name.value -eq "RAGZRSStorageUsage" }).currentValue / 1GB), 2)
 
    $totalVault = [math]::Round(($lrs + $grs + $zrs + $gzrs), 2)
 
    $vaultRecord = [PSCustomObject]@{
        SubscriptionName   = $subscriptionName
        VaultName          = $vaultName
        VaultResourceGroup = $resourceGroup
        LRS                = $lrs
        GRS                = $grs
        ZRS                = $zrs
        GZRS               = $gzrs
        TotalVault         = $totalVault
    }
  
            $vaultUsageData += $vaultRecord
 
        } catch {
            Write-Warning "Failed to fetch usage for vault $vaultName in $subscriptionName : $($_.Exception.Message)"
        }
    }
}
 
# Export to CSV
$vaultUsageData | Export-Csv -Path "VaultUsageReport.csv" -NoTypeInformation
 
$fileName = "VaultUsageReport.csv"

# Upload to Azure Storage
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($csvPath)

$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false

Write-Output "Backup report uploaded to Azure Storage container '$containerName' as '$blobName'."