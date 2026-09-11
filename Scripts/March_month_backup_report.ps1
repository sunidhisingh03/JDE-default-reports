# Powershell script to fetch Backup Report
param(
    $todaysDate = (Get-Date -Format "dd_MM_yyyy_hh_mm_ss")
)

# Connect using Managed Identity
Connect-AzAccount -Identity
   
$vmBackupReport = @()
$allsubscription = Get-AzSubscription
 
 
foreach ($subscription in $allsubscription) {
    Set-AzContext -Subscription $subscription.Id
    $vms = Get-AzVM
    Write-Host "Collecting all Backup Recovery Vault information for subscription: $($subscription.Name)" -BackgroundColor DarkGreen
 
    $backupVaults = Get-AzRecoveryServicesVault
 
    foreach ($vm in $vms) {
        $recoveryVaultInfo = Get-AzRecoveryServicesBackupStatus -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Type 'AzureVM'
 
        if ($recoveryVaultInfo.BackedUp -eq $true) {
            Write-Host "$($vm.Name) - BackedUp : Yes"
 
            # Backup Recovery Vault Information
            $vmBackupVault = $backupVaults | Where-Object { $_.ID -eq $recoveryVaultInfo.VaultId }
 
            # Backup Container and Item
            $container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -VaultId $vmBackupVault.ID -FriendlyName $vm.Name
            $backupItem = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vmBackupVault.ID
 
            # Get Backup Jobs for March 2026 (UTC)
            $startTime = Get-Date -Year 2026 -Month 3 -Day 1 -Hour 0 -Minute 0 -Second 0 -AsUTC
            $endTime   = Get-Date -Year 2026 -Month 3 -Day 31 -Hour 23 -Minute 59 -Second 59 -AsUTC

            $backupJobs = Get-AzRecoveryServicesBackupJob -VaultId $vmBackupVault.ID -BackupManagementType AzureVM -From $startTime -To $endTime | Where-Object { $_.WorkloadName -eq $vm.Name }
 
            if ($backupJobs.Count -gt 0) {
                foreach ($job in $backupJobs) {
                    $vmBackupReport += [PSCustomObject]@{
                        SubscriptionName             = $subscription.Name
                        VM_Name                      = $vm.Name
                        VM_Location                  = $vm.Location
                        VM_ResourceGroupName         = $vm.ResourceGroupName
                        VM_BackedUp                  = $recoveryVaultInfo.BackedUp
                        VM_RecoveryVaultName         = $vmBackupVault.Name
                        VM_RecoveryVaultPolicy       = $backupItem.ProtectionPolicyName
                        VM_LastBackupStatus          = $backupItem.LastBackupStatus
                        VM_LastBackupTime            = $backupItem.LastBackupTime
                        VM_BackupDeleteState         = $backupItem.DeleteState
                        VM_BackupLatestRecoveryPoint = $backupItem.LatestRecoveryPoint
                        VM_Id                        = $vm.Id
                        BackupJob_Id                 = $job.JobId
                        BackupJob_Operation          = $job.Operation
                        BackupJob_Status             = $job.Status
                        BackupJob_StartTime          = $job.StartTime
                        BackupJob_EndTime            = $job.EndTime
                        BackupJob_Duration           = $job.Duration.ToString()
                        BackupJob_ErrorCode          = $job.ErrorDetails.ErrorCode
                        BackupJob_ErrorMessage       = $job.ErrorDetails.ErrorMessage
                        BackupJob_Recommendations    = $job.ErrorDetails.Recommendations
                    }
                }
            } else {
                # No jobs found but VM is backed up
                $vmBackupReport += [PSCustomObject]@{
                    SubscriptionName             = $subscription.Name
                    VM_Name                      = $vm.Name
                    VM_Location                  = $vm.Location
                    VM_ResourceGroupName         = $vm.ResourceGroupName
                    VM_BackedUp                  = $recoveryVaultInfo.BackedUp
                    VM_RecoveryVaultName         = $vmBackupVault.Name
                    VM_RecoveryVaultPolicy       = $backupItem.ProtectionPolicyName
                    VM_LastBackupStatus          = $backupItem.LastBackupStatus
                    VM_LastBackupTime            = $backupItem.LastBackupTime
                    VM_BackupDeleteState         = $backupItem.DeleteState
                    VM_BackupLatestRecoveryPoint = $backupItem.LatestRecoveryPoint
                    VM_Id                        = $vm.Id
                    BackupJob_Id                 = ""
                    BackupJob_Operation          = ""
                    BackupJob_Status             = ""
                    BackupJob_StartTime          = ""
                    BackupJob_EndTime            = ""
                    BackupJob_Duration           = ""
                    BackupJob_ErrorCode          = ""
                    BackupJob_ErrorMessage       = ""
                    BackupJob_Recommendations    = ""
                }
            }
        } else {
            Write-Host "$($vm.Name) - BackedUp : No" -BackgroundColor DarkRed
            $vmBackupReport += [PSCustomObject]@{
                SubscriptionName             = $subscription.Name
                VM_Name                      = $vm.Name
                VM_Location                  = $vm.Location
                VM_ResourceGroupName         = $vm.ResourceGroupName
                VM_BackedUp                  = $false
                VM_RecoveryVaultName         = ""
                VM_RecoveryVaultPolicy       = ""
                VM_LastBackupStatus          = ""
                VM_LastBackupTime            = ""
                VM_BackupDeleteState         = ""
                VM_BackupLatestRecoveryPoint = ""
                BackupJob_Id                 = ""
                BackupJob_Operation          = ""
                BackupJob_Status             = ""
                BackupJob_StartTime          = ""
                BackupJob_EndTime            = ""
                BackupJob_Duration           = ""
                BackupJob_ErrorCode          = ""
                BackupJob_ErrorMessage       = ""
                BackupJob_Recommendations    = ""
            }
        }
    }
}
 
# Export to CSV
$csvPath = "Azure_Monthly_Backup_Jobs.csv"
$vmBackupReport | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8



Write-Output "Backup report generated successfully at $csvPath"

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
$base64_csv = [Convert]::ToBase64String([IO.File]::ReadAllBytes($csvPath))
 
 
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
            Subject = 'JDE(IT) | Azure | Backup Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
                    <p>Please find attached JDE Azure Backup Report for your reference..</p>
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
                }
            #,
            #     @{ 
            #     address = 'eslam.mahmoud@jdecoffee.com'    
            #     displayName = 'Mahmoud, Eslam'
            #     },
            #    @{ 
            #     address = 'farhan.malik@jdecoffee.com'
            #     displayName = 'Malik, Farhan' 
            #     },
            #    @{
            #      address = 'ismetkursat.caliskan@jdecoffee.com'
            #      displayName = 'Ismetkursat' 
            #      }
 
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
            name = $($csvPath)
            contentType = "text/csv"
            contentInBase64 = $($base64_csv)
           }
        )
    } | ConvertTo-Json -Depth 100
}
(Invoke-WebRequest @params -UseBasicParsing).RawContent
