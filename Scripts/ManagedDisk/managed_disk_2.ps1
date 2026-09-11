Connect-AzAccount -Identity
  
Function ManagedDisks{
param()
try{    
    $diskData = @()
    # $manageddisks = search-azgraph -query "resources | where type =~ 'microsoft.compute/disks'" -first 1000 -subscription $subscription.id
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
Write-Output "Creating CSV file for Disks Data..."
Write-Output $script:diskDataReport
$csvPath = "Azure_Managed_Disks.csv"
$script:diskDataReport | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Force
 
 
$fileName = "Azure_Managed_Disks.csv"
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
$base64_csv = [Convert]::ToBase64String([IO.File]::ReadAllBytes($fileName))
 
 
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
            Subject = 'JDE(IT) | Azure | Managed Disk'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
                    <p>Please find attached JDE Azure Managed Disk Report for your reference..</p>
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