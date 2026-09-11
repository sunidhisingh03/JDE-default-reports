
Connect-AzAccount -Identity

#region Functions

Function Get-VMUptimeData {
    param(
        [string]$SubscriptionId,
        [string]$VMName,
        [string]$ResourceGroup,
        [int]$Days = 30
    )

    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

    # Fetch VM and current power state
    $vm = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroup
    $vmStatus = Get-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -Status
    $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).Code  # e.g., "PowerState/running"

    # Friendly state: only the part after '/' (e.g., running, stopped, deallocated)
    $friendlyState = if ([string]::IsNullOrWhiteSpace($powerState)) {
        'unknown'
    } elseif ($powerState -match '/') {
        (($powerState -split '/')[1]).ToLowerInvariant()
    } else {
        $powerState.ToLowerInvariant()
    }

    $resourceId = $vm.Id

    $endDate = Get-Date
    $startDate = $endDate.AddDays(-1 * $Days)

    # Query Activity Log for Start/Deallocate events within the window
    $events = Get-AzActivityLog -StartTime $startDate -EndTime $endDate `
        -ResourceId $resourceId -MaxRecord 10000 |
        Where-Object { $_.OperationName -in @("Start Virtual Machine", "Deallocate Virtual Machine") } |
        Sort-Object EventTimestamp

    $availableHours = 0.0
    $lastStart = $null
    $seenDeallocateInWindow = $false

    if ($events.Count -eq 0) {
        # No events in window: infer based on current power state
        if ($friendlyState -eq "running") {
            # VM running now -> assume running entire window (start happened before window)
            $availableHours = (New-TimeSpan -Start $startDate -End $endDate).TotalHours
        } else {
            # VM not running -> zero availability
            $availableHours = 0
        }
    } else {
        # If first event is Deallocate, with no Start before it in the window,
        # assume VM was running at window start until that deallocation
        $first = $events[0]
        if ($first.OperationName -eq "Deallocate Virtual Machine") {
            $seenDeallocateInWindow = $true
            $availableHours += (New-TimeSpan -Start $startDate -End $first.EventTimestamp).TotalHours
        }

        foreach ($event in $events) {
            if ($event.OperationName -eq "Start Virtual Machine") {
                $lastStart = $event.EventTimestamp
            }
            elseif ($event.OperationName -eq "Deallocate Virtual Machine") {
                $seenDeallocateInWindow = $true
                if ($lastStart) {
                    # Count uptime from last Start to this Deallocate
                    $availableHours += (New-TimeSpan -Start $lastStart -End $event.EventTimestamp).TotalHours
                    $lastStart = $null
                }
            }
        }

        # If last event was Start and VM still running, count up to now
        if ($lastStart -and ($friendlyState -eq "running")) {
            $availableHours += (New-TimeSpan -Start $lastStart -End $endDate).TotalHours
        }
        # If there was NO deallocate during the window and VM is running,
        # assume VM ran for the entire window (start occurred before window)
        elseif (-not $seenDeallocateInWindow -and ($friendlyState -eq "running")) {
            $availableHours = (New-TimeSpan -Start $startDate -End $endDate).TotalHours
        }
    }

    $totalHours = $Days * 24
    $availabilityPercent = if ($totalHours -gt 0) {
        [math]::Round(($availableHours / $totalHours) * 100, 2)
    } else { 0 }

    return [PSCustomObject]@{
        "Virtual Machine"        = $VMName
        "Subscription Name"      = (Get-AzSubscription -SubscriptionId $SubscriptionId).Name
        "Resource Group"         = $ResourceGroup
        "Total Hours"            = $totalHours
        "Available Hours"        = [math]::Round($availableHours, 2)
        "Availability (Percent)" = $availabilityPercent
        "Current VM State"       = $friendlyState   # <-- only value after '/', normalized
    }
}

Function ServerAvailabilityReport {
    param(
        [int]$Days = 30
    )

    $report = @()
    $subs = Get-AzSubscription

    foreach ($sub in $subs) {
        Set-AzContext -SubscriptionId $sub.Id | Out-Null
        $vms = Get-AzVM

        foreach ($vm in $vms) {
            $data = Get-VMUptimeData -SubscriptionId $sub.Id -VMName $vm.Name -ResourceGroup $vm.ResourceGroupName -Days $Days
            $report += ,$data
        }
    }


    # Prepare CSV in memory
    $csvContent = $report | ConvertTo-Csv -NoTypeInformation | Out-String
    $csvBytes = [System.Text.Encoding]::UTF8.GetBytes($csvContent)
    $csvBase64 = [Convert]::ToBase64String($csvBytes)

    # Prepare HTML summary (updated with Current VM State column)
    $top20 = $report | Sort-Object "Availability (Percent)" -Descending | Select-Object -First 20
    $bottom20 = $report | Sort-Object "Availability (Percent)" | Select-Object -First 20

     $html = @"
&lt;html&gt;
&lt;head&gt;
&lt;style&gt;
{font-family: sans-serif; font-size: 10pt;}
TABLE {border: 1px solid black; border-collapse: collapse; font-size:13pt;width: 100%;}
TH {border: 1px solid white; font-size: 10pt;background-color: rgb(55, 124, 159); padding: 5px; color: white;}
TD {border: 1px solid black; font-size: 10pt;padding: 5px;}
body {background-color: #ffffff;}
h2 {background-color: rgb(55, 124, 159); color: #ffffff;text-align: center;}
h3 {background-color: rgb(55, 124, 159); color: #ffffff;text-align: center;}
&lt;/style&gt;
&lt;/head&gt;
&lt;body&gt;
&lt;h2&gt;Top 20 Azure VM Availability Report&lt;/h2&gt;
&lt;table&gt;
&lt;tr&gt;
&lt;th&gt;Subscription Name&lt;/th&gt;
&lt;th&gt;Virtual Machine&lt;/th&gt;
&lt;th&gt;Resource Group&lt;/th&gt;
&lt;th&gt;Total Hours&lt;/th&gt;
&lt;th&gt;Available Hours&lt;/th&gt;
&lt;th&gt;Availability (%)&lt;/th&gt;
&lt;th&gt;Current VM State&lt;/th&gt;
&lt;/tr&gt;
"@
foreach ($row in $top20) {
    $color = if ($row.'Availability (Percent)' -lt 90) { "#ffbf00" } else { "#ccffcc" }
    $html += "&lt;tr&gt;
&lt;td&gt;$($row.'Subscription Name')&lt;/td&gt;
&lt;td&gt;$($row.'Virtual Machine')&lt;/td&gt;
&lt;td&gt;$($row.'Resource Group')&lt;/td&gt;
&lt;td style='text-align:center'&gt;$($row.'Total Hours')&lt;/td&gt;
&lt;td style='text-align:center'&gt;$($row.'Available Hours')&lt;/td&gt;
&lt;td style='background-color:$color; text-align:center'&gt;$($row.'Availability (Percent)')&lt;/td&gt;
&lt;td&gt;$($row.'Current VM State')&lt;/td&gt;
&lt;/tr&gt;"
}

$html += "&lt;/table&gt;
&lt;h2&gt;Bottom 20 Azure VM Availability Report&lt;/h2&gt;
&lt;table&gt;
&lt;tr&gt;
&lt;th&gt;Subscription Name&lt;/th&gt;
&lt;th&gt;Virtual Machine&lt;/th&gt;
&lt;th&gt;Resource Group&lt;/th&gt;
&lt;th&gt;Total Hours&lt;/th&gt;
&lt;th&gt;Available Hours&lt;/th&gt;
&lt;th&gt;Availability (%)&lt;/th&gt;
&lt;th&gt;Current VM State&lt;/th&gt;
&lt;/tr&gt;
"

foreach ($row in $bottom20) {
    $color = if ($row.'Availability (Percent)' -lt 90) { "#ffbf00" } else { "#ccffcc" }
    $html += "&lt;tr&gt;
&lt;td&gt;$($row.'Subscription Name')&lt;/td&gt;
&lt;td&gt;$($row.'Virtual Machine')&lt;/td&gt;
&lt;td&gt;$($row.'Resource Group')&lt;/td&gt;
&lt;td style='text-align:center'&gt;$($row.'Total Hours')&lt;/td&gt;
&lt;td style='text-align:center'&gt;$($row.'Available Hours')&lt;/td&gt;
&lt;td style='background-color:$color; text-align:center'&gt;$($row.'Availability (Percent)')&lt;/td&gt;
&lt;td&gt;$($row.'Current VM State')&lt;/td&gt;
&lt;/tr&gt;"
}

$html += "&lt;/table&gt;
&lt;h3&gt;Developed By - Elastic Ops Autonomics&lt;/h3&gt;
&lt;/body&gt;
&lt;/html&gt;"

    return @{ Html = $html; CsvBase64 = $csvBase64 }
}

# Generate report
$reportData = ServerAvailabilityReport
$htmlReport = $reportData.Html
$csvPath = "AzureVM_30DayAvailability.csv"
$csvBase64 = $reportData.CsvBase64

#endregion



=======
# ==============================
#  ACS EMAIL (send the report)
# ==============================


$authority = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
$resourceUrl = "https://communication.azure.com"
$clientId = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
$body = @{
  grant_type    = "client_credentials"
  client_id     = $clientId
  client_secret = Get-AutomationVariable -Name "client_secret"
  resource      = $resourceUrl
}
$response = Invoke-WebRequest -Method Post -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
$accessToken = $response.Content | ConvertFrom-Json
$uuid = [guid]::NewGuid().ToString()
$gmt  = Get-Date -Format U

$params = @{
  Method  = 'POST'
  URI     = 'https://eops-acs.australia.communication.azure.com/emails:send?api-version=2023-03-31'
  Headers = @{
    Authorization               = 'Bearer ' + $accessToken.access_token
    'Content-Type'              = 'application/json'
    'repeatability-first-sent'  = $gmt
    'repeatability-request-id'  = $uuid
  }
  Body = @{
    senderAddress = 'hcl-elasticops@85f0f5ea-7143-4ae8-ba66-6bf624fe1fd4.azurecomm.net'
    content = @{
      subject   = 'JDE(IT) | Azure | Server Availability Report'
      plainText = 'used azure communication service'
      html      = "<html><head><title> !</title></head><body><p>Greetings,</p>
                         <p>Please find attached JDE Azure Server Availability Report for your reference.</p>
                         <p>Note that this is automatically generated email via HCL ElasticOps Azure DevOps System. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCLTECH.COM</p>
                         <p><br>Regards,</p>
                         <p>EOPS AUTONOMICS</p>
                         </body></html>"
    }
    recipients = @{
      to = @(
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
      cc = @(
        @{
          address     = 'archana_maurya@hcltech.com'
          displayName = 'Archana Maurya'
        },
        @{
          address     = 'sunidhi.kumari@hcltech.com'
          displayName = 'Sunidhi Kumari'
        }
      )
    }
    attachments = @(
      @{
        name            = $csvPath
        contentType     = 'text/csv'
        contentInBase64 = $csvBase64
      }
    )
  } | ConvertTo-Json -Depth 100
}

(Invoke-WebRequest @params -UseBasicParsing).RawContent
