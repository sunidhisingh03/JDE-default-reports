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
            Subject = 'JDE(IT) | Azure | Snapshot Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
                    <p>Please find attached JDE Azure Snapshot Report for your reference..</p>
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