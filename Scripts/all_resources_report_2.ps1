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
 
$fileName = "Azure_All_Resources.csv"
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
            Subject = 'JDE(IT) | Azure | All Resource Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
                    <p>Please find attached JDE Azure All Resources Report for your reference..</p>
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


