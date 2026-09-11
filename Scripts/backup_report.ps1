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
 
            # Get Backup Jobs for last 1 day
            $currentTime = [System.DateTime]::UtcNow
            $startTime = (Get-Date $currentTime -Hour 0 -Minute 0 -Second 0 ).AddMonths(-1).AddDays(1)
            $endTime = (Get-Date $currentTime -Hour 0 -Minute 0 -Second 0)
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
 
# Upload to Azure Storage
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$blobName = [System.IO.Path]::GetFileName($csvPath)

$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false

Write-Output "Backup report uploaded to Azure Storage container '$containerName' as '$blobName'."