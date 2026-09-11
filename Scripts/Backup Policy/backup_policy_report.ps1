# param(
#  $todaysDate = (Get-Date -Format "dd_MM_yyyy_hh_mm_ss")
# )

# Connect-AzAccount -Identity

# $script:policyData = @()
# $csvPath = "Azure_Backup_Policy_Report.csv"

# # Get all subscriptions
# $subscriptions = Get-AzSubscription

# foreach ($subscription in $subscriptions) {
#  Write-Output "Processing Subscription: $($subscription.Name)"
#  Set-AzContext -Subscription $subscription.Id

#  try {
#  $vaults = Get-AzRecoveryServicesVault
#  if (-not $vaults) { Write-Output "No vaults found in subscription $($subscription.Name)" }

#  foreach ($vault in $vaults) {
#  Write-Output "Processing Vault: $($vault.Name)"
#  Set-AzRecoveryServicesVaultContext -Vault $vault

#  # Get all backup policies in the vault
#  $policies = Get-AzRecoveryServicesBackupProtectionPolicy
 
#  if (-not $policies) { Write-Output "No policies found in vault $($vault.Name)" }

#  foreach ($policy in $policies) {
#  Write-Output "Found Policy: $($policy.Name)"

#  # Full Backup details
#  $fullBackup = if ($policy.SchedulePolicy) {
#  $frequency = $policy.SchedulePolicy.ScheduleRunFrequency
#  $times = if ($policy.SchedulePolicy.ScheduleRunTimes) {
#  ($policy.SchedulePolicy.ScheduleRunTimes | ForEach-Object { $_.ToString("MM/dd/yyyy hh:mm tt") }) -join ', '
#  } else { "Not Configured" }
#  "Frequency: $frequency; Time: $times"
#  } else { "Not Configured" }

#  # Differential Backup
#  $diffBackup = if ($policy.SchedulePolicy.DifferentialBackupScheduleEnabled) { "Enabled" } else { "Disabled" }

#  # Log Backup details
#  $logBackup = if ($policy.SchedulePolicy.LogBackupFrequencyInMinutes) {
#  "Frequency: Every $($policy.SchedulePolicy.LogBackupFrequencyInMinutes) min; Retention: $($policy.RetentionPolicy.DailySchedule.DurationInDays) days"
#  } else { "Not Configured" }

#  # Prepare data row (Removed Associated Items)
#  $dataRow = [pscustomobject]@{
#  "Subscription Name" = $subscription.Name
#  "Vault Name" = $vault.Name
#  "Resource Group Name" = $vault.ResourceGroupName
#  "Policy Name" = $policy.Name
#  "Workload Type" = $policy.WorkloadType
#  "Backup Management Type" = $policy.BackupManagementType
#  "Backup Time" = ($policy.SchedulePolicy.ScheduleRunTimes -join ', ')
#  "Full Backup Details" = $fullBackup
#  "Differential Backup" = $diffBackup
#  "Log Backup Details" = $logBackup
#  }

#  $script:policyData += $dataRow
#  }
#  }
#  } catch {
#  Write-Output "Error while processing subscription $($subscription.Name): $($_.Exception.Message)"
#  }
# }

# # Export even if empty
# $script:policyData | Export-Csv -Path $csvPath -Force -NoTypeInformation -Encoding UTF8
# Write-Output "Detailed Backup Policy Report generated: $csvPath"

# $authority = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
# $resourceUrl = "https://communication.azure.com"
# $clientId = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
# $body = @{grant_type = "client_credentials"
#           client_id = $clientId
#           client_secret = Get-AutomationVariable -Name "client_secret"
#           resource = 'https://communication.azure.com'
# }
# $response = Invoke-WebRequest -Method Post -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
# $accessToken = $response.Content | ConvertFrom-Json
# $accessToken.access_token
# $uuid = [guid]::NewGuid().ToString()
# $gmt = get-date -format U
# $base64_csv = [Convert]::ToBase64String([IO.File]::ReadAllBytes($csvPath))
 
 
# $params = @{
#     Method = 'POST'
#     URI = 'https://eops-acs.australia.communication.azure.com/emails:send?api-version=2023-03-31'
#     Headers = @{
#         Authorization = 'Bearer ' + $accessToken.access_token
#         'Content-Type' = 'application/json'
#         'repeatability-first-sent' = $gmt
#         'repeatability-request-id' = $uuid
#     }
#     Body = @{
#         senderAddress = 'hcl-elasticops@aa34110f-dc60-463e-b5cf-bd3b7c8ce04d.azurecomm.net'
#         Content = @{
#             Subject = 'JDE | Azure | Backup Policy Report'
#             PlainText = 'used azure communication service'
#             html = "<html><head><title> !</title></head><body><p>Greetings,</p>
#                     <p>Please find attached JDE Azure Backup Policy Report for your reference..</p>
#                     <p>
#                         Note that this is automatically generated email via HCL ElasticOps Azure DevOps System. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCLTECH.COM</p>
#                      <p><br>Regards,</p>
#                      <p>EOPS AUTONOMICS</p>
#                      </body></html>"
#         }
#         recipients = @{
#             To = @(
#                 @{
#                 address = 'DL-Cloud-JDE@hcltech.com'
#                 displayName = 'DL-Cloud-JDE'
#                 }
 
#             )
#             Cc = @(
 
#                @{
#                 address = 'archana_maurya@hcltech.com'
#                 displayName = 'Archana Maurya'
#                },
#                @{
#                 address = 'sunidhi.kumari@hcltech.com'
#                 displayName = 'Sunidhi Kumari'
#                 }
#             )
#         }
#         Attachments = @(
#            @{ 
#             name = $($csvPath)
#             contentType = "text/csv"
#             contentInBase64 = $($base64_csv)
#            }
#         )
#     } | ConvertTo-Json -Depth 100
# }
# (Invoke-WebRequest @params -UseBasicParsing).RawContent
param(

    # $todaysDate = (Get-Date -Format "dd_MM_yyyy_hh_mm_ss")

)

Connect-AzAccount -Identity
$script:policyData = @()
$csvPath = "Azure_Backup_Policy_Report.csv"
$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Write-Output "Processing Subscription $($subscription.Name)"
    Set-AzContext -Subscription $subscription.Id
    try {
        $vaults = Get-AzRecoveryServicesVault
        if (-not $vaults) {
            Write-Output "No vaults found in subscription $($subscription.Name)"
        }
        foreach ($vault in $vaults) {
            Write-Output "Processing Vault: $($vault.Name)"
            Set-AzRecoveryServicesVaultContext -Vault $vault
            $policies = Get-AzRecoveryServicesBackupProtectionPolicy
            if (-not $policies) {
                Write-Output "No policies found in vault $($vault.Name)"
            }
            foreach ($policy in $policies) {
                Write-Output "Found Policy: $($policy.Name)"
                $fullBackup = if ($policy.SchedulePolicy) {
                    $frequency = $policy.SchedulePolicy.ScheduleRunFrequency
                    $times = if ($policy.SchedulePolicy.ScheduleRunTimes) {
                        ($policy.SchedulePolicy.ScheduleRunTimes |
                            ForEach-Object { $_.ToString("MM/dd/yyyy hh:mm tt") }) -join ', '
                    }
                    else {
                        "Not Configured"
                    }
                    "Frequency: $frequency; Time: $times"
                }
                else {
                    "Not Configured"
                }
                $diffBackup = if ($policy.SchedulePolicy.DifferentialBackupScheduleEnabled) {
                    "Enabled"
                }
                else {
                    "Disabled"
                }
                $logBackup = if ($policy.SchedulePolicy.LogBackupFrequencyInMinutes) {
                    "Frequency: Every $($policy.SchedulePolicy.LogBackupFrequencyInMinutes) min; " +
                    "Retention: $($policy.RetentionPolicy.DailySchedule.DurationInDays) days"
                }
                else {
                    "Not Configured"
                }
                # ============ CHANGE START: Added Retention Details ============
                $retentionDetails = @()
                if ($policy.RetentionPolicy.DailySchedule) {
                    $retentionDetails += "Daily: $($policy.RetentionPolicy.DailySchedule.DurationCountInDays) days"
                }
                if ($policy.RetentionPolicy.WeeklySchedule) {
                    $retentionDetails += "Weekly: $($policy.RetentionPolicy.WeeklySchedule.DurationCountInWeeks) weeks"
                }
                if ($policy.RetentionPolicy.MonthlySchedule) {
                    $retentionDetails += "Monthly: $($policy.RetentionPolicy.MonthlySchedule.DurationCountInMonths) months"
                }
                if ($policy.RetentionPolicy.YearlySchedule) {
                    $retentionDetails += "Yearly: $($policy.RetentionPolicy.YearlySchedule.DurationCountInYears) years"
                }
                $retentionInfo = if ($retentionDetails.Count -gt 0) {
                    $retentionDetails -join '; '
                } else {
                    "Not Configured"
                }
                # ============ CHANGE END: Added Retention Details ============
                # ============ CHANGE START: Added Associated Items (VMs/SQL DBs) ============
                $associatedItems = @()
                try {
                    $backupItems = Get-AzRecoveryServicesBackupItem `
                        -BackupManagementType $policy.BackupManagementType `
                        -WorkloadType $policy.WorkloadType `
                        -VaultId $vault.ID
                    foreach ($item in $backupItems) {
                        if ($item.ProtectionPolicyName -eq $policy.Name) {
                            if ($policy.WorkloadType -eq 'MSSQL' -or $policy.WorkloadType -eq 'SQLDataBase') {
                                $associatedItems += $item.FriendlyName
                            }
                            else {
                                $associatedItems += $item.Name
                            }
                        }
                    }
                }
                catch {
                    Write-Output "Warning: Could not retrieve backup items for policy $($policy.Name): $($_.Exception.Message)"
                }
                $itemsList = if ($associatedItems.Count -gt 0) {
                    $associatedItems -join '; '
                } else {
                    "No items assigned"
                }
                # ============ CHANGE END: Added Associated Items (VMs/SQL DBs) ============
                # ============ CHANGE START: Updated dataRow with new columns ============
                $dataRow = [pscustomobject]@{
                    "Subscription Name"      = $subscription.Name
                    "Vault Name"             = $vault.Name
                    "Resource Group Name"    = $vault.ResourceGroupName
                    "Policy Name"            = $policy.Name
                    "Workload Type"          = $policy.WorkloadType
                    "Backup Management Type" = $policy.BackupManagementType
                    "Backup Time"            = ($policy.SchedulePolicy.ScheduleRunTimes -join ', ')
                    "Full Backup Details"    = $fullBackup
                    "Differential Backup"    = $diffBackup
                    "Log Backup Details"     = $logBackup
                    "Retention Policy"       = $retentionInfo
                    #"Associated Items"       = $itemsList
                }
                # ============ CHANGE END: Updated dataRow with new columns ============
                $script:policyData += $dataRow
            }
        }
    }
    catch {
        Write-Output "Error while processing subscription $($subscription.Name): $($_.Exception.Message)"
    }
}
$script:policyData |
    Export-Csv -Path $csvPath -Force -NoTypeInformation -Encoding UTF8
Write-Output "Detailed Backup Policy Report generated: $csvPath"
$authority   = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
$resourceUrl = "https://communication.azure.com"
$clientId    = "abddebe4-5f78-49f0-936d-c365d6b8e78d"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = Get-AutomationVariable -Name "client_secret"
    resource      = $resourceUrl
}
$response    = Invoke-WebRequest -Method Post -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded'
$accessToken = ($response.Content | ConvertFrom-Json).access_token
$uuid        = [guid]::NewGuid().ToString()
$gmt         = Get-Date -Format U
$base64_csv  = [Convert]::ToBase64String([IO.File]::ReadAllBytes($csvPath))
$params = @{

    Method  = 'POST'

    URI     = 'https://eops-acs.australia.communication.azure.com/emails:send?api-version=2023-03-31'

    Headers = @{

        Authorization              = "Bearer $accessToken"

        'Content-Type'             = 'application/json'

        'repeatability-first-sent' = $gmt

        'repeatability-request-id' = $uuid

    }

    Body = @{
  
        senderAddress = 'hcl-elasticops@85f0f5ea-7143-4ae8-ba66-6bf624fe1fd4.azurecomm.net'

        content       = @{

            subject   = 'JDE | Azure | Backup Policy Report'

            plainText = 'Used Azure Communication Service'

            html      = @"
<html>
<head><title></title></head>
<body>
<p>Greetings,</p>
<p>Please find attached JDE Azure Backup Policy Report for your reference.</p>
<p>Note that this is automatically generated email via HCL ElasticOps Azure DevOps System.
For any queries or issues, please contact EOPS.</p>
<p><br/>Regards,</p>
<p>EOPS AUTONOMICS</p>
</body>
</html>
"@
        }
        recipients = @{
            to = @(
                @{
                    address     = 'swati-soni@hcltech.com'
                    displayName = 'swati soni'
                }

            ) 
            Cc = @(
               @{
                address = 'sunidhi.kumari@hcltech.com'
                displayName = 'Sunidhi Kumari'
                }
            )
      
        }
        Attachments = @(
            @{
                name        = $($csvPath)
                contentType = 'text/csv'
                contentInBase64 =  $($base64_csv)
            }
        )
    } | ConvertTo-Json -Depth 10
}
Invoke-RestMethod @params