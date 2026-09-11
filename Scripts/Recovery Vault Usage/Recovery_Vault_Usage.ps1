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
$authority = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
$resourceUrl = "https://communication.azure.com"
$clientId = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
$body = @{grant_type = "client_credentials"
          client_id = $clientId
          client_secret = Get-AutomationVariable -Name "client_secret"
          resource = 'https://communication.azure.com'
}
$response = Invoke-WebRequest -Method Post -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
$accessToken = $response.Content | ConvertFrom-Json
$accessToken.access_token
$uuid = [guid]::NewGuid().ToString()
$gmt = get-date -format U
$base64_csv = [Convert]::ToBase64String([IO.File]::ReadAllBytes($fileName ))
 
 
$params = @{
    Method = 'POST'
    URI = 'https://eops-acs.australia.communication.azure.com/emails:send?api-version=2023-03-31'
    Headers = @{
        Authorization = 'Bearer ' + $accessToken.access_token
        'Content-Type' = 'application/json'
        'repeatability-first-sent' = $gmt
        'repeatability-request-id' = $uuid
    }
    Body = @{
        senderAddress = 'hcl-elasticops@85f0f5ea-7143-4ae8-ba66-6bf624fe1fd4.azurecomm.net'
        Content = @{
            Subject = 'JDE(IT) | Azure | Recovery Vault Usage Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
                    <p>Please find attached JDE Azure Recovery Vault Usage Report for your reference..</p>
                    <p>
                        Note that this is automatically generated email via HCL ElasticOps Azure DevOps System. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCLTECH.COM</p>
                     <p><br>Regards,</p>
                     <p>EOPS AUTONOMICS</p>
                     </body></html>"
        }
        recipients = @{
            To = @(
                @{
                address = 'DL-Cloud-JDE@hcltech.com'
                displayName = 'DL-Cloud-JDE'
                },
                @{ 
                address = 'eslam.mahmoud@jdecoffee.com'    
                displayName = 'Mahmoud, Eslam'
                },
               @{ 
                address = 'farhan.malik@jdecoffee.com'
                displayName = 'Malik, Farhan' 
                },
               @{
                 address = 'ismetkursat.caliskan@jdecoffee.com'
                 displayName = 'Ismetkursat' 
                 }
 
            )
            Cc = @(
 
               @{
                address = 'archana_maurya@hcltech.com'
                displayName = 'Archana Maurya'
               },

               @{
                address = 'sunidhi.kumari@hcltech.com'
                displayName = 'Sunidhi Kumari'
                }
            )
        }
        Attachments = @(
           @{ 
            name = $($fileName)
            contentType = "text/csv"
            contentInBase64 = $($base64_csv)
           }
        )
    } | ConvertTo-Json -Depth 100
}
(Invoke-WebRequest @params -UseBasicParsing).RawContent

