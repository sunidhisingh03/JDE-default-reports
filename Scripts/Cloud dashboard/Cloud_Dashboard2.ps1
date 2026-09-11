#cloud dashboard report

Connect-AzAccount -Identity

Function Compute {
  param()
  try {
    Write-Output "Fetching Virtual Machines..."
    $script:vms = Get-AzVM -Status -ErrorAction SilentlyContinue
    $script:vmCount += ($script:vms | Measure-Object).Count

    Write-Output "Fetching Managed Disks..."
    $script:managedDisks = Get-AzDisk -ErrorAction SilentlyContinue
    $script:managedDisksCount += ($script:managedDisks | Measure-Object).Count

    Write-Output "Fetching Restore Point Collections..."
    $script:restorePoints = Get-AzRestorePointCollection -ErrorAction SilentlyContinue
    $script:restorePointsCount += ($script:restorePoints | Measure-Object).Count

    Write-Output "Fetching Availability Sets..."
    $script:availabilitySets = Get-AzAvailabilitySet -ErrorAction SilentlyContinue
    $script:availabilitySetsCount += ($script:availabilitySets | Measure-Object).Count

    Write-Output "Fetching SSH Public Keys..."
    $script:sshPublicKeys = Get-AzSshPublicKey -ErrorAction SilentlyContinue
    $script:sshPublicKeysCount += ($script:sshPublicKeys | Measure-Object).Count

    Write-Output "Fetching Snapshots..."
    $script:snapshots = Get-AzSnapshot -ErrorAction SilentlyContinue
    $script:snapshotsCount += ($script:snapshots | Measure-Object).Count

    Write-Output "Classifying Windows vs Non-Windows VMs..."
    $script:windowsMachines     = $script:vms | Where-Object { $_.StorageProfile.OSDisk.OsType -eq 'Windows' }
    $script:nonWindowsMachines  = $script:vms | Where-Object { $_.StorageProfile.OSDisk.OsType -ne 'Windows' }
    $script:windowsMachinesCount     += ($script:windowsMachines     | Measure-Object).Count
    $script:nonWindowsMachinesCount  += ($script:nonWindowsMachines  | Measure-Object).Count
  }
  catch { Write-Output "Error while fetching compute resources - $($_.Exception.Message)" }
}

Function Network {
  param()
  try {
    Write-Output "Fetching Route Tables..."
    $script:routeTables = Get-AzRouteTable -ErrorAction SilentlyContinue
    $script:routeTablesCount += ($script:routeTables | Measure-Object).Count

    Write-Output "Fetching Network Security Groups..."
    $script:networkSecurityGroups = Get-AzNetworkSecurityGroup -ErrorAction SilentlyContinue
    $script:networkSecurityGroupsCount += ($script:networkSecurityGroups | Measure-Object).Count

    Write-Output "Fetching Virtual Networks..."
    $script:virtualNetworks = Get-AzVirtualNetwork -ErrorAction SilentlyContinue
    $script:virtualNetworksCount += ($script:virtualNetworks | Measure-Object).Count

    Write-Output "Fetching Network Interfaces..."
    $script:networkInterfaces = Get-AzNetworkInterface -ErrorAction SilentlyContinue
    $script:networkInterfacesCount += ($script:networkInterfaces | Measure-Object).Count

    Write-Output "Fetching Express Route Circuits..."
    $script:expressRouteCircuits = Get-AzExpressRouteCircuit -ErrorAction SilentlyContinue
    $script:expressRouteCircuitsCount += ($script:expressRouteCircuits | Measure-Object).Count

    Write-Output "Fetching Public IP Addresses..."
    $script:publicIPAddresses = Get-AzPublicIpAddress -ErrorAction SilentlyContinue
    $script:publicIpAddressesCount += ($script:publicIPAddresses | Measure-Object).Count

    Write-Output "Fetching Load Balancers..."
    $script:loadBalancers = Get-AzLoadBalancer -ErrorAction SilentlyContinue
    $script:loadBalancersCount += ($script:loadBalancers | Measure-Object).Count

    Write-Output "Fetching Bastion Hosts..."
    $script:bastionHosts = Get-AzBastion -ErrorAction SilentlyContinue
    $script:bastionHostsCount += ($script:bastionHosts | Measure-Object).Count

    Write-Output "Fetching Application Security Groups..."
    $script:applicationSecurityGroups = Get-AzApplicationSecurityGroup -ErrorAction SilentlyContinue
    $script:applicationSecurityGroupsCount += ($script:applicationSecurityGroups | Measure-Object).Count

    Write-Output "Fetching Virtual Network Gateway Connections..."
    $script:connections = Get-AzVirtualNetworkGatewayConnection -ErrorAction SilentlyContinue
    $script:connectionsCount += ($script:connections | Measure-Object).Count

    Write-Output "Fetching Virtual Network Gateways..."
    $script:virtualNetworkGateways = Get-AzVirtualNetworkGateway -ErrorAction SilentlyContinue
    $script:virtualNetworkGatewaysCount += ($script:virtualNetworkGateways | Measure-Object).Count

    Write-Output "Fetching Local Network Gateways..."
    $script:localNetworkGateways = Get-AzLocalNetworkGateway -ErrorAction SilentlyContinue
    $script:localNetworkGatewaysCount += ($script:localNetworkGateways | Measure-Object).Count
  }
  catch { Write-Output "Error while fetching network resources - $($_.Exception.Message)" }
}

Function DataAndStorage {
  param()
  try {
    Write-Output "Fetching Storage Accounts..."
    $script:storageAccounts = Get-AzStorageAccount -ErrorAction SilentlyContinue
    $script:storageAccountsCount += ($script:storageAccounts | Measure-Object).Count

    Write-Output "Fetching Databricks Workspaces..."
    $script:workspaces = Get-AzDatabricksWorkspace -ErrorAction SilentlyContinue
    $script:workspacesCount += ($script:workspaces | Measure-Object).Count

    Write-Output "Fetching Data Factories..."
    $script:factories = Get-AzDataFactory -ErrorAction SilentlyContinue
    $script:factoriesCount += ($script:factories | Measure-Object).Count

    Write-Output "Fetching Storage Sync Services..."
    $script:storageSyncServices = Get-AzStorageSyncService -ErrorAction SilentlyContinue
    $script:storageSyncServicesCount += ($script:storageSyncServices | Measure-Object).Count
  }
  catch { Write-Output "Error while fetching data and storage details - $($_.Exception.Message)" }
}

Function MicrosoftSQL {
  param()
  try {
    Write-Output "Fetching SQL Server Databases..."
    $script:databases = Get-AzSqlDatabase -ErrorAction SilentlyContinue
    $script:sqlDatabasesCount += ($script:databases | Measure-Object).Count

    Write-Output "Fetching SQL Servers..."
    $script:servers = Get-AzSqlServer -ErrorAction SilentlyContinue
    $script:sqlServersCount += ($script:servers | Measure-Object).Count

    Write-Output "Fetching SQL Server Elastic Pools..."
    $script:elasticPools = Get-AzSqlElasticPool -ErrorAction SilentlyContinue
    $script:elasticPoolsCount += ($script:elasticPools | Measure-Object).Count

    Write-Output "Fetching SQL Virtual Machines..."
    $script:sqlVirtualMachines = Get-AzSqlVM -ErrorAction SilentlyContinue
    $script:sqlVirtualMachinesCount += ($script:sqlVirtualMachines | Measure-Object).Count
  }
  catch { Write-Output "Error while fetching SQL details - $($_.Exception.Message)" }
}

Function RunningVsDeallocated {
  param()
  try {
    # $runningCount = 0
    $stoppedCount = 0
    $script:stoppedVms = @()

    Write-Output "Fetching Running Vs Deallocated Machines..."
    foreach($vm in $script:vms){
      $powerStatus = ($vm.InstanceView.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
      if($powerStatus -eq 'VM running'){
        $runningCount += 1
      }
      else{
        $stoppedCount += 1
        $script:stoppedVms += $vm.Name
      }
    }

    if($script:stoppedVms -and $script:stoppedVms.Count -gt 0){
$script:vmData += @"
<tr>
  <td>$($Subscription.Name)</td>
  <td>$stoppedCount</td>
  <td>$($script:stoppedVms -join ',')</td>
</tr>
"@
    }
    else{
$script:vmData += @"
<tr>
  <td>$($Subscription.Name)</td>
  <td>$stoppedCount</td>
  <td>There are no deallocated virtual machines for this subscription.</td>
</tr>
"@
    }
  }
  catch { Write-Output "Error while fetching running vs deallocated machines - $($_.Exception.Message)" }
}

Function VmInventory {
  param()
  try {
    Write-Output "Fetching Protected Items (Azure VM backup) across vaults..."
    $script:protectedItems = @()
    $vaults = Get-AzRecoveryServicesVault -ErrorAction SilentlyContinue
    foreach($v in $vaults){
      Set-AzRecoveryServicesVaultContext -VaultId $v.ID -ErrorAction SilentlyContinue
      $items = Get-AzRecoveryServicesBackupItem -WorkloadType 'AzureVM' -ErrorAction SilentlyContinue
      if($items){ $script:protectedItems += $items }
    }
    $script:protectedItemsCount = ($script:protectedItems | Measure-Object).Count

    Write-Output "Building VM Inventory with Backup Status and Primary IP..."
    $inventoryD = @()

    foreach($vm in $script:vms){
      # Primary NIC
      $primaryNicId     = ($vm.NetworkProfile.NetworkInterfaces | Select-Object -First 1).Id
      $nic              = $script:networkInterfaces | Where-Object { $_.Id -eq $primaryNicId } | Select-Object -First 1
      $primaryIpAddress = $nic.IpConfigurations[0].PrivateIpAddress

      # Backup Status
      $backupStatus = 'Not Configured'
      foreach($item in $script:protectedItems){
        if($item.Properties.SourceResourceId -eq $vm.Id){ $backupStatus = 'Configured'; break }
      }

      # OS Version
      $osType    = $vm.StorageProfile.OSDisk.OsType
      $osVersion = $vm.InstanceView.OsName
      if([string]::IsNullOrWhiteSpace($osVersion)){ $osVersion = 'NA' }

      $powerStatus = ($vm.InstanceView.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
      $sku         = $vm.HardwareProfile.VmSize

$inventoryD += @"
<tr>
  <td>$($Subscription.Name)</td>
  <td>$($vm.Name)</td>
  <td>$($vm.ResourceGroupName)</td>
  <td>$($primaryIpAddress)</td>
  <td>$($osType)</td>
  <td>$($osVersion)</td>
  <td>$($sku)</td>
  <td>$($powerStatus)</td>
  <td>$($backupStatus)</td>
</tr>
"@
    }

    $script:inventoryData += $inventoryD
  }
  catch { Write-Output "Error while fetching inventory data - $($_.Exception.Message)" }
}

Function DiskAnalysis {
  param()
  try {
    Write-Output "Fetching Disks State and Tier..."
    foreach($disk in $script:managedDisks){
      if($disk.DiskState -eq 'Reserved'){ $script:reservedDisksCount  += 1 }
      else                              { $script:unreservedDisksCount += 1 }

      if($disk.Sku.Name -like 'Premium*'){ $script:premiumDisksCount  += 1 }
      else                               { $script:standardDisksCount += 1 }
    }
  }
  catch { Write-Output "Error while fetching disk state and tier - $($_.Exception.Message)" }
}

Function Automation {
  param()
  try {
    Write-Output "Fetching Automation Accounts..."
    $script:automationAccounts = Get-AzAutomationAccount -ErrorAction SilentlyContinue
    $script:automationAccountsCount += ($script:automationAccounts | Measure-Object).Count

    Write-Output "Fetching Automation Runbooks..."
    $script:automationRunbooks = @()
    foreach($acct in $script:automationAccounts){
      $script:automationRunbooks += (Get-AzAutomationRunbook -AutomationAccountName $acct.AutomationAccountName -ResourceGroupName $acct.ResourceGroupName -ErrorAction SilentlyContinue)
    }
    $script:automationRunbooksCount += ($script:automationRunbooks | Measure-Object).Count

    Write-Output "Fetching Logic App Workflows..."
    $script:logicWorkflows = Get-AzLogicApp -ErrorAction SilentlyContinue
    $script:logicWorkflowsCount += ($script:logicWorkflows | Measure-Object).Count

    Write-Output "Fetching Key Vaults..."
    $script:KeyVaults = Get-AzKeyVault -ErrorAction SilentlyContinue
    $script:KeyVaultsCount += ($script:KeyVaults | Measure-Object).Count
  }
  catch { Write-Output "Error while fetching automation account details - $($_.Exception.Message)" }
}

Function HTMLReport {
  param()
  try {
    $htmlReport = @"
<html>
<head>
<title>JDE Dashboard</title>
<meta charset='utf-8'>
<style>
body { font-family: Arial, Helvetica, sans-serif; background-color: #66CDAA; }
h1 { box-shadow: 5px 5px 4px rgba(0,0,0,0.2); text-align: center; background-color: #009879; color: white; }
h3 { box-shadow: 5px 5px 4px rgba(0,0,0,0.2); text-align: center; background-color: #009879; color: white; font-size: large; }
h2 { box-shadow: 5px 5px 4px rgba(0,0,0,0.2); text-align: center; background-color: #009879; color: white; }
.cards { display:flex; flex-wrap: wrap; gap: 15px; }
.cards_item { background-color:#009879; flex-basis:12%; padding: 10px; margin-left: 8%; margin-right: 1%; box-shadow: 5px 5px 4px rgba(0,0,0,0.2); }
.cards_item > p { box-shadow: none; font-size: small; color: white; }
.cards_item > h3 { box-shadow: none; font-size: small; color: white; }
table, th { width: 100%; text-align: center; table-layout: fixed; border-collapse: collapse; border: 1px solid #009879; background-color: #66cdaa; }
th { background-color: #009879; color: white; }
td { color: black; word-wrap: break-word; border: 1px solid #009879; font-size: small; }
tr:nth-child(odd){ background-color: cadetblue; }
</style>
</head>
<body>
<h1>JDE Cloud Dashboard</h1>
<h2>Subscription Count: $subscriptionCount</h2>

<!-- ### Compute Resources ### -->
<h2>Compute Resources</h2>
<div class='cards'>
  <div class='cards_item'><h3>Virtual Machines</h3><p>$vmCount</p></div>
  <div class='cards_item'><h3>Managed Disks</h3><p>$managedDisksCount</p></div>
  <div class='cards_item'><h3>Restore Point Collections</h3><p>$restorePointsCount</p></div>
  <div class='cards_item'><h3>Availability Sets</h3><p>$availabilitySetsCount</p></div>
  <div class='cards_item'><h3>SSH Public Keys</h3><p>$sshPublicKeysCount</p></div>
  <div class='cards_item'><h3>Snapshots</h3><p>$snapshotsCount</p></div>
  <div class='cards_item'><h3>Windows Machines</h3><p>$windowsMachinesCount</p></div>
  <div class='cards_item'><h3>Non Windows Machines</h3><p>$nonWindowsMachinesCount</p></div>
  <div class='cards_item'><h3>Reserved Disks</h3><p>$reservedDisksCount</p></div>
  <div class='cards_item'><h3>Unreserved Disks</h3><p>$unreservedDisksCount</p></div>
  <div class='cards_item'><h3>Premium Disks</h3><p>$premiumDisksCount</p></div>
  <div class='cards_item'><h3>Standard Disks</h3><p>$standardDisksCount</p></div>
</div>

<!-- ### Network Resources ### -->
<h2>Network Resources</h2>
<div class='cards'>
  <div class='cards_item'><h3>Route Tables</h3><p>$routeTablesCount</p></div>
  <div class='cards_item'><h3>Network Security Groups</h3><p>$networkSecurityGroupsCount</p></div>
  <div class='cards_item'><h3>Virtual Networks</h3><p>$virtualNetworksCount</p></div>
  <div class='cards_item'><h3>Application Security Groups</h3><p>$applicationSecurityGroupsCount</p></div>
  <div class='cards_item'><h3>Bastion Hosts</h3><p>$bastionHostsCount</p></div>
  <div class='cards_item'><h3>Network Connections</h3><p>$connectionsCount</p></div>
  <div class='cards_item'><h3>Express Route Circuits</h3><p>$expressRouteCircuitsCount</p></div>
  <div class='cards_item'><h3>Load Balancers</h3><p>$loadBalancersCount</p></div>
  <div class='cards_item'><h3>Local Network Gateways</h3><p>$localNetworkGatewaysCount</p></div>
  <div class='cards_item'><h3>Network Interfaces</h3><p>$networkInterfacesCount</p></div>
  <div class='cards_item'><h3>Public IP Addresses</h3><p>$publicIpAddressesCount</p></div>
  <div class='cards_item'><h3>Virtual Network Gateways</h3><p>$virtualNetworkGatewaysCount</p></div>
</div>

<!-- ### Data & Storage Resources ### -->
<h2>Database & Storage Resources</h2>
<div class='cards'>
  <div class='cards_item'><h3>SQL Servers</h3><p>$sqlServersCount</p></div>
  <div class='cards_item'><h3>SQL Server Databases</h3><p>$sqlDatabasesCount</p></div>
  <div class='cards_item'><h3>Elastic Pools</h3><p>$elasticPoolsCount</p></div>
  <div class='cards_item'><h3>SQL Virtual Machines</h3><p>$sqlVirtualMachinesCount</p></div>
  <div class='cards_item'><h3>Storage Accounts</h3><p>$storageAccountsCount</p></div>
  <div class='cards_item'><h3>Databricks Workspaces</h3><p>$workspacesCount</p></div>
  <div class='cards_item'><h3>Data Factories</h3><p>$factoriesCount</p></div>
  <div class='cards_item'><h3>Storage Sync Services</h3><p>$storageSyncServicesCount</p></div>
</div>

<!-- ### Automation Resources ### -->
<h2>Automation Resources</h2>
<div class='cards'>
  <div class='cards_item'><h3>Automation Accounts</h3><p>$automationAccountsCount</p></div>
  <div class='cards_item'><h3>Automation Runbooks</h3><p>$automationRunbooksCount</p></div>
  <div class='cards_item'><h3>Logic App Workflows</h3><p>$logicWorkflowsCount</p></div>
  <div class='cards_item'><h3>Key Vaults</h3><p>$KeyVaultsCount</p></div>
</div>

<!-- ### Running Vs Deallocated VM ### -->
<h2>Running Vs Deallocated Virtual Machines</h2>
<table>
<tr>
  <th>Subscription Name</th>
  <th>Total Running</th>
  <th>Total Stopped</th>
  <th>Stopped Virtual Machines</th>
</tr>
$vmData
</table>

<!-- ### VM Inventory ### -->
<h2>Virtual Machines Inventory</h2>
<table>
<tr>
  <th>Subscription Name</th>
  <th>HostName</th>
  <th>Resource Group</th>
  <th>Primary IP Address</th>
  <th>OS Type</th>
  <th>OS Version</th>
  <th>SKU</th>
  <th>Status</th>
  <th>Backup</th>
</tr>
$inventoryData
</table>

<h3>Developed By - ElasticOps Autonomics</h3>
</body>
</html>
"@

    if($htmlReport){
      $htmlReport | Out-File -FilePath "Primark_Cloud_Dashboard.html" -Encoding utf8 -Force
    }
  }
  catch { Write-Output "Error while creating HTML file - $($_.Exception.Message)" }
}


# compute
$script:vmCount = 0
$script:managedDisksCount = 0
$script:restorePointsCount = 0
$script:availabilitySetsCount = 0
$script:sshPublicKeysCount = 0
$script:snapshotsCount = 0
$script:windowsMachinesCount = 0
$script:nonWindowsMachinesCount = 0

# network
$script:routeTablesCount = 0
$script:networkSecurityGroupsCount = 0
$script:virtualNetworksCount = 0
$script:applicationSecurityGroupsCount = 0
$script:bastionHostsCount = 0
$script:connectionsCount = 0
$script:expressRouteCircuitsCount = 0
$script:loadBalancersCount = 0
$script:localNetworkGatewaysCount = 0
$script:networkInterfacesCount = 0
$script:publicIpAddressesCount = 0
$script:virtualNetworkGatewaysCount = 0

# data & storage
$script:storageAccountsCount = 0
$script:workspacesCount = 0
$script:factoriesCount = 0
$script:storageSyncServicesCount = 0

# sql
$script:sqlVirtualMachinesCount = 0
$script:elasticPoolsCount = 0
$script:sqlServersCount = 0
$script:sqlDatabasesCount = 0

# running vs deallocated
$script:vmData = @()

# VM inventory
$script:inventoryData = @()

# disk analysis
$script:reservedDisksCount = 0
$script:unreservedDisksCount = 0
$script:premiumDisksCount = 0
$script:standardDisksCount = 0

# automation
$script:KeyVaultsCount = 0
$script:logicWorkflowsCount = 0
$script:automationRunbooksCount = 0
$script:automationAccountsCount = 0

# subscriptions Count
$subscriptionCount = 0

############################################
###            Subscription loop          ###
############################################

Write-Output "Fetching all subscriptions..."
$Subscriptions = Get-AzSubscription -ErrorAction Stop
$subscriptionCount += ($Subscriptions | Measure-Object).Count

foreach($Subscription in $Subscriptions){
  Write-Output "Setting Context to $($Subscription.Name)"
  Set-AzContext -Subscription $Subscription.Id | Out-Null

  Write-Output "Fetching Compute resources..."
  Compute

  Write-Output "Fetching Network resources..."
  Network

  Write-Output "Fetching Data and Storage resources..."
  DataAndStorage

  Write-Output "Fetching SQL resources..."
  MicrosoftSQL

  Write-Output "Fetching Running Vs Deallocated resources..."
  RunningVsDeallocated

  Write-Output "Fetching Inventory..."
  VmInventory

  Write-Output "Fetching Disk state and tier..."
  DiskAnalysis

  Write-Output "Fetching Automation resources..."
  Automation
}

Write-Output "Creating HTML file..."
HTMLReport



# --- Ensure HTML exists ---
$htmlPath = "JDE_Cloud_Dashboard.html"
if (!(Test-Path -Path $htmlPath)) { throw "HTML dashboard not found: $htmlPath" }

# --- OAuth token for ACS (service principal in Azure Automation) ---
$authority    = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
$resourceUrl  = "https://communication.azure.com"
$clientId     = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
$clientSecret = Get-AutomationVariable -Name "client_secret"

$body = @{
  grant_type    = "client_credentials"
  client_id     = $clientId
  client_secret = $clientSecret
  resource      = $resourceUrl
}

$response     = Invoke-WebRequest -Method POST -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
$accessToken  = $response.Content | ConvertFrom-Json

# --- Repeatability headers (RFC1123 UTC) ---
$uuid = [guid]::NewGuid().ToString()
$gmt  = [DateTime]::UtcNow.ToString("r")   # e.g., "Fri, 19 Dec 2025 09:24:43 GMT"

# --- Base64 HTML attachment ---
$base64_html = [Convert]::ToBase64String([IO.File]::ReadAllBytes($htmlPath))

# --- Compose ACS email payload (HTML-only attachment) ---
$params = @{
  Method  = 'POST'
  Uri     = 'https://eops-acs.australia.communication.azure.com/emails:send?api-version=2023-03-31'
  Headers = @{
    Authorization               = "Bearer $($accessToken.access_token)"
    'Content-Type'              = 'application/json'
    'Repeatability-First-Sent'  = $gmt
    'Repeatability-Request-Id'  = $uuid
  }
  Body = @{
    senderAddress = 'hcl-elasticops@85f0f5ea-7143-4ae8-ba66-6bf624fe1fd4.azurecomm.net'
    content = @{
      subject   = "JDE(IT) Cloud Dashboard | $(Get-Date -Format 'dd-MMM-yyyy HH:mm')"
      plainText = "Used Azure Communication Service. The HTML dashboard is attached."
      html      = @"
<html>
  <body>
    <p>Greetings,</p>
    <p>Please find attached the latest <b>JDE Cloud Dashboard</b> (HTML).</p>
    <p><i>Tip:</i> Double-click the HTML attachment to open it in your default browser (Microsoft Edge recommended).</p>
    <p>Note that this is an automatically generated email via HCL ElasticOps Azure DevOps System.
       For any queries or concerns, please reach out to AUTONOMICS-DEVOPS@HCLTECH.COM.</p>
    <p>Regards,<br/>EOPS AUTONOMICS</p>
  </body>
</html>
"@
    }
    recipients = @{
      to = @(
        @{
          address = 'DL-Cloud-JDE@hcltech.com'
          displayName = 'DL-Cloud-JDE'
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
        name             = [System.IO.Path]::GetFileName($htmlPath)
        contentType      = "text/html"
        contentInBase64  = $base64_html
      }
    )
  } | ConvertTo-Json -Depth 100
}

# --- Send email ---
$sendResult = Invoke-WebRequest @params -UseBasicParsing
WriteWrite-Output "ACS send response:"
