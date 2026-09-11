Connect-AzAccount -Identity
Function VMStatus {
    param()
    try {
        $vmData = @()
        $vms = Get-AzVM
        foreach ($vm in $vms) {
            if ($vm.ResourceGroupName -ne "pi0026") {
                $nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id
                $nic = Get-AzNetworkInterface -ResourceId $nicId
                $privateIp = $nic.IpConfigurations[0].PrivateIpAddress

                $vmInstanceView = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status

                $dataRow = [pscustomobject]@{
                    "Subscription Name" = (Get-AzContext).Subscription.Name
                    "Virtual Machine" = $vm.Name
                    "ResourceGroup" = $vm.ResourceGroupName
                    "Private Ip Address" = $privateIp
                    "State" = $vmInstanceView.Statuses | Where-Object { $_.Code -like "PowerState*" } | Select-Object -ExpandProperty DisplayStatus
                    "OS Type" = $vm.StorageProfile.OsDisk.OsType
                    "OS Name" = $vmInstanceView.OsName
                    "OS Version" = $vmInstanceView.OsVersion
                }

                $vmData += $dataRow
            }
        }

        $script:vmStatus += $vmData
    } catch {
        Write-Output "Error while fetching VM status - $($_.Exception.Message)"
    }
}

$script:vmStatus = @()

Write-Output "Fetching all subscriptions..."
$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Write-Output "Setting context to subscription $($subscription.Name)..."
    Set-AzContext -SubscriptionId $subscription.Id
    Write-Output "Fetching VM status for current subscription..."
    VMStatus
}

Write-Output "Creating CSV file for VM Data..."
$vmStatus | Export-Csv -Path "Azure_VM_Inventory.csv" -NoTypeInformation -Encoding UTF8 -Force
$fileName = "Azure_VM_Inventory.csv"

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
            Subject = 'JDE(IT) | Azure | VM Inventory'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
                    <p>Please find attached JDE Azure VM Inventory for your reference..</p>
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
