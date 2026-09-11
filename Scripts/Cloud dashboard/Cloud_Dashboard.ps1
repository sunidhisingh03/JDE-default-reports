
param(
  $todaysDate = (Get-Date -Format "dd_MM_yyyy_hh_mm_ss")
)

# Connect using Managed Identity
Connect-AzAccount -Identity

############################
# Functions
############################

Function Compute{
param()
  Write-Output "Fetching Virtual Machines..."
  # Use -Status so InstanceView (OsName, PowerState) is populated
  $script:vms = Get-AzVM -Status
  if($vms){ $script:vmCount += $vms.Count } else { $script:vmCount += 0 }

  Write-Output "Fetching Managed Disks..."
  $script:managedDisks = Get-AzDisk
  if($managedDisks){ $script:managedDisksCount += $managedDisks.Count } else { $script:managedDisksCount += 0 }

  Write-Output "Fetching Restore Point Collections..."
  $script:restorePoints = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Compute/restorePointCollections" }
  if($restorePoints){ $script:restorePointsCount += $restorePoints.Count } else { $script:restorePointsCount += 0 }

  Write-Output "Fetching Availability Sets..."
  $script:availabilitySets = Get-AzAvailabilitySet
  if($availabilitySets){ $script:availabilitySetsCount += $availabilitySets.Count } else { $script:availabilitySetsCount += 0 }

  Write-Output "Fetching SSH Public Keys..."
  $script:sshPublicKeys = Get-AzSshKey
  if($sshPublicKeys){ $script:sshPublicKeysCount += $sshPublicKeys.Count } else { $script:sshPublicKeysCount += 0 }

  Write-Output "Fetching Snapshots..."
  $script:snapshots = Get-AzSnapshot
  if($snapshots){ $script:snapshotsCount += $snapshots.Count } else { $script:snapshotsCount += 0 }

  Write-Output "Fetching Windows Machines..."
  $script:windowsMachines = $vms | Where-Object { $_.StorageProfile.OsDisk.OsType -eq "Windows" }
  if($windowsMachines){ $script:windowsMachinesCount += $windowsMachines.Count } else { $script:windowsMachinesCount += 0 }

  Write-Output "Fetching Non Windows Machines..."
  $script:nonWindowsMachines = $vms | Where-Object { $_.StorageProfile.OsDisk.OsType -ne "Windows" }
  if($nonWindowsMachines){ $script:nonWindowsMachinesCount += $nonWindowsMachines.Count } else { $script:nonWindowsMachinesCount += 0 }
}

Function Network{
param()
  Write-Output "Fetching Route Tables..."
  $script:routeTables = Get-AzRouteTable
  if($routeTables){ $script:routeTablesCount += $routeTables.Count } else { $script:routeTablesCount += 0 }

  Write-Output "Fetching Network Security Groups..."
  $script:networkSecurityGroups = Get-AzNetworkSecurityGroup
  if($networkSecurityGroups){ $script:networkSecurityGroupsCount += $networkSecurityGroups.Count } else { $script:networkSecurityGroupsCount += 0 }

  Write-Output "Fetching Virtual Networks..."
  $script:virtualNetworks = Get-AzVirtualNetwork
  if($virtualNetworks){ $script:virtualNetworksCount += $virtualNetworks.Count } else { $script:virtualNetworksCount += 0 }

  Write-Output "Fetching Network Interfaces..."
  $script:networkInterfaces = Get-AzNetworkInterface
  if($networkInterfaces){ $script:networkInterfacesCount += $networkInterfaces.Count } else { $script:networkInterfacesCount += 0 }

  Write-Output "Fetching Express Route Circuits..."
  $script:expressRouteCircuits = Get-AzExpressRouteCircuit
  if($expressRouteCircuits){ $script:expressRouteCircuitsCount += $expressRouteCircuits.Count } else { $script:expressRouteCircuitsCount += 0 }

  Write-Output "Fetching Public IP Addresses..."
  $script:publicIPAddresses = Get-AzPublicIpAddress
  if($publicIPAddresses){ $script:publicIpAddressesCount += $publicIPAddresses.Count } else { $script:publicIpAddressesCount += 0 }

  Write-Output "Fetching Load Balancers..."
  $script:loadBalancers = Get-AzLoadBalancer
  if($loadBalancers){ $script:loadBalancersCount += $loadBalancers.Count } else { $script:loadBalancersCount += 0 }

  Write-Output "Fetching Bastion Hosts..."
  $script:bastionHosts = Get-AzBastion
  if($bastionHosts){ $script:bastionHostsCount += $bastionHosts.Count } else { $script:bastionHostsCount += 0 }

  Write-Output "Fetching Application Security Groups..."
  $script:applicationSecurityGroups = Get-AzApplicationSecurityGroup
  if($applicationSecurityGroups){ $script:applicationSecurityGroupsCount += $applicationSecurityGroups.Count } else { $script:applicationSecurityGroupsCount += 0 }

  Write-Output "Fetching Connections..."
  $script:connections = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Network/connections" }
  if($connections){ $script:connectionsCount += $connections.Count } else { $script:connectionsCount += 0 }

  Write-Output "Fetching Virtual Network Gateways..."
  $script:virtualNetworkGateways = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Network/virtualNetworkGateways" }
  if($virtualNetworkGateways){ $script:virtualNetworkGatewaysCount += $virtualNetworkGateways.Count } else { $script:virtualNetworkGatewaysCount += 0 }

  Write-Output "Fetching Local Network Gateways..."
  $script:localNetworkGateways = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Network/localNetworkGateways" }
  if($localNetworkGateways){ $script:localNetworkGatewaysCount += $localNetworkGateways.Count } else { $script:localNetworkGatewaysCount += 0 }
}

Function DataAndStorage{
param()
  Write-Output "Fetching Storage Accounts..."
  $script:storageAccounts = Get-AzStorageAccount
  if($storageAccounts){ $script:storageAccountsCount += $storageAccounts.Count } else { $script:storageAccountsCount += 0 }

  Write-Output "Fetching Databricks Workspaces..."
  $script:workspaces = Get-AzDatabricksWorkspace
  if($workspaces){ $script:workspacesCount += $workspaces.Count } else { $script:workspacesCount += 0 }

  Write-Output "Fetching Data Factories..."
  $script:factories = Get-AzDataFactoryV2
  if($factories){ $script:factoriesCount += $factories.Count } else { $script:factoriesCount += 0 }

  Write-Output "Fetching Storage Sync Services..."
  $script:storageSyncServices = Get-AzStorageSyncService
  if($storageSyncServices){ $script:storageSyncServicesCount += $storageSyncServices.Count } else { $script:storageSyncServicesCount += 0 }
}

Function MicrosoftSQL{
param()
  Write-Output "Fetching SQL Server Databases..."
  $script:databases = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Sql/servers/databases" }
  if($databases){ $script:sqlDatabasesCount += $databases.Count } else { $script:sqlDatabasesCount += 0 }

  Write-Output "Fetching SQL Servers..."
  $script:servers = Get-AzSqlServer
  if($servers){ $script:sqlServersCount += $servers.Count } else { $script:sqlServersCount += 0 }

  Write-Output "Fetching SQL Server Elastic Pools..."
  $script:elasticpools = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Sql/servers/elasticpools" }
  if($elasticpools){ $script:elasticpoolsCount += $elasticpools.Count } else { $script:elasticpoolsCount += 0 }

  Write-Output "Fetching SQL Virtual Machines..."
  $script:SqlVirtualMachines = Get-AzSqlVM
  if($SqlVirtualMachines){ $script:SqlVirtualMachinesCount += $SqlVirtualMachines.Count } else { $script:SqlVirtualMachinesCount += 0 }
}

Function RunningVsDeallocated{
param()
    $stoppedCount = 0
    $script:stoppedVms = @()

    Write-Output "Fetching Running Vs Deallocated Machines..."
    foreach($vm in $vms){
        switch ($vm.PowerState) {
            "VM deallocated" { $stoppedCount++; $script:stoppedVms += $vm.Name }
            "VM stopped"     { $stoppedCount++; $script:stoppedVms += $vm.Name }
            default { } # ignore running and other transient states
        }
    }

    if($script:stoppedVms){
        $script:vmData += "<tr>
<td>$($Subscription.Name)</td>
<td>$stoppedCount</td>
<td>$($script:stoppedVms -join ",")</td>
</tr>"
    } else {
        $script:vmData += "<tr>
<td>$($Subscription.Name)</td>
<td>$stoppedCount</td>
<td>There are no deallocated/stopped virtual machines for this subscription.</td>
</tr>"
    }
}


Function DiskAnalysis{
param()
  Write-Output "Fetching Disks State and Tier..."
  foreach($disk in $managedDisks){
    if($disk.DiskState -eq "Reserved"){ $script:reservedDisksCount += 1 } else { $script:unReservedDisksCount += 1 }
    if($disk.Sku.Tier -eq "Premium"){ $script:premiumDisksCount += 1 } else { $script:StandardDisksCount += 1 }
  }
}

Function Automation{
param()
  Write-Output "Fetching Automation Accounts..."
  $script:automationAccounts = Get-AzAutomationAccount
  if($automationAccounts){ $script:automationAccountsCount += $automationAccounts.Count } else { $script:automationAccountsCount += 0 }

  Write-Output "Fetching Automation Runbooks..."
  $script:automationRunbooks = Get-AzResource | Where-Object { $_.ResourceType -eq "Microsoft.Automation/automationAccounts/runbooks" }
  if($automationRunbooks){ $script:automationRunbooksCount += $automationRunbooks.Count } else { $script:automationRunbooksCount += 0 }

  Write-Output "Fetching Logic App Workflows..."
  $script:logicWorkflows = Get-AzLogicApp
  if($logicWorkflows){ $script:logicWorkflowsCount += $logicWorkflows.Count } else { $script:logicWorkflowsCount += 0 }

  Write-Output "Fetching Key Vaults..."
  $script:KeyVaults = Get-AzKeyVault
  if($KeyVaults){ $script:KeyVaultsCount += $KeyVaults.Count } else { $script:KeyVaultsCount += 0 }
}

Function HTMLReport{
param()
$script:htmlReport = @"
<html>
<head>
<title>JDE Cloud Dashboard</title>
<meta charset="utf-8">
<Style>
body { font-family: Arial, Helvetica, sans-serif; background-color: #66CDAA; }
h1{ box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2); text-align: center; background-color: #009879; color: white; }
h2{ box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2); text-align: center; background-color: #009879; color: white; font-size: large; }
h3{ box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2); text-align: center; background-color: #009879; color: white; }
.cards{ display:flex; flex-wrap: wrap; gap: 15px 15px; }
.cards_item{ background-color:#009879; flex-basis:12%; padding-left: 10px; padding-right: 10px; margin-left: 8%; margin-right: 1%; box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2); }
.cards_item > p { box-shadow: none; font-size: small; }
.cards_item > h3 { box-shadow: none; font-size: small; }
table, th{ width: 100%; text-align: center; table-layout: fixed; border-collapse: collapse; border: 1px solid #009879; background-color: #66cdaa; }
th{ background-color: #009879; color: white; }
td{ color: black; word-wrap: break-word; border: 1px solid #009879; font-size: small; }
tr:nth-child(odd){ background-color: cadetblue; }
</Style>
</head>
<body>
<h1>JDE Cloud Dashboard</h1>
<h2>Subscription Count: $subscriptionCount</h2>

<h2>Compute Resources</h2>
<div class="cards">
  <div class="cards_item"><h3>Virtual Machines<h3><p>$vmCount</p></div>
  <div class="cards_item"><h3>Managed Disks<h3><p>$managedDisksCount</p></div>
  <div class="cards_item"><h3>Restore Point Collections<h3><p>$restorePointsCount</p></div>
  <div class="cards_item"><h3>Availability Sets<h3><p>$availabilitySetsCount</p></div>
  <div class="cards_item"><h3>Snapshots<h3><p>$snapshotsCount</p></div>
  <div class="cards_item"><h3>Windows Machines<h3><p>$windowsMachinesCount</p></div>
  <div class="cards_item"><h3>Non Windows Machines<h3><p>$nonWindowsMachinesCount</p></div>
</div>

<h2>Network Resources</h2>
<div class="cards">
  <div class="cards_item"><h3>Route Tables<h3><p>$routeTablesCount</p></div>
  <div class="cards_item"><h3>Network Security Groups<h3><p>$networkSecurityGroupsCount</p></div>
  <div class="cards_item"><h3>Virtual Networks<h3><p>$virtualNetworksCount</p></div>
  <div class="cards_item"><h3>Application Security Groups<h3><p>$applicationSecurityGroupsCount</p></div>
  <div class="cards_item"><h3>Bastion Hosts<h3><p>$bastionHostsCount</p></div>
  <div class="cards_item"><h3>Network Connections<h3><p>$connectionsCount</p></div>
  <div class="cards_item"><h3>Express Route Circuits<h3><p>$expressRouteCircuitsCount</p></div>
  <div class="cards_item"><h3>Load Balancers<h3><p>$loadBalancersCount</p></div>
  <div class="cards_item"><h3>Local Network Gateways<h3><p>$localNetworkGatewaysCount</p></div>
  <div class="cards_item"><h3>Network Interfaces<h3><p>$networkInterfacesCount</p></div>
  <div class="cards_item"><h3>Public IP Addresses<h3><p>$publicIpAddressesCount</p></div>
  <div class="cards_item"><h3>Virtual Network Gateways<h3><p>$virtualNetworkGatewaysCount</p></div>
</div>

<h2>Database & Storage Resources</h2>
<div class="cards">
  <div class="cards_item"><h3>SQL Server Databases<h3><p>$sqlDatabasesCount</p></div>
  <div class="cards_item"><h3>Elastic Pools<h3><p>$elasticpoolsCount</p></div>
  <div class="cards_item"><h3>SQL Virtual Machines<h3><p>$SqlVirtualMachinesCount</p></div>
  <div class="cards_item"><h3>Storage Accounts<h3><p>$storageAccountsCount</p></div>
  <div class="cards_item"><h3>Databricks Workspaces<h3><p>$workspacesCount</p></div>
  <div class="cards_item"><h3>Data Factories<h3><p>$factoriesCount</p></div>
  <div class="cards_item"><h3>Storage Sync Services<h3><p>$storageSyncServicesCount</p></div>
  <div class="cards_item"><h3>Key Vaults<h3><p>$KeyVaultsCount</p></div>
</div>

<h2>Deallocated/Stopped Virtual Machines</h2>
<table>
<tr>
  <th>Subscription Name</th>
  <th>Total Stopped/Deallocated</th>
  <th>Stopped/Deallocated Virtual Machines</th>
</tr>
$vmData
</table>

<h3>Developed By - ElasticOps Autonomics</h3>
</body>
</html>
"@
}

############################
# Variables
############################

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

# storage & data
$script:storageAccountsCount = 0
$script:workspacesCount = 0
$script:factoriesCount = 0
$script:storageSyncServicesCount = 0

# sql
$script:SqlVirtualMachinesCount = 0
$script:elasticpoolsCount = 0
$script:sqlServersCount = 0
$script:sqlDatabasesCount = 0

# running vs deallocated
$script:vmData = @()

# disk analysis
$script:reservedDisksCount = 0
$script:unReservedDisksCount = 0
$script:premiumDisksCount = 0
$script:StandardDisksCount = 0

# automation
$script:KeyVaultsCount = 0
$script:logicWorkflowsCount = 0
$script:automationRunbooksCount = 0
$script:automationAccountsCount = 0

# subscriptions
$subscriptionCount = 0

############################
# Main
############################

Write-Output "Fetching all subscriptions..."
$Subscriptions = Get-AzSubscription
$subscriptionCount += $Subscriptions.Count

if($Subscriptions){
  foreach($subscription in $Subscriptions){
    Write-Output "Setting Context to $($subscription.Name)"
    Set-AzContext -Subscription $subscription.Id

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

    Write-Output "Fetching Disk state and tier..."
    DiskAnalysis

    Write-Output "Fetching Automation resources..."
    Automation
  }
}

Write-Output "Creating HTML file..."
HTMLReport
$ReportFileName = "JDE_Cloud_Dashboard.html"
$script:htmlReport | Out-File -FilePath $ReportFileName -Encoding utf8 -Force

############################
# Email via Azure Communication Service
############################

$TenantId = '189de737-c93a-4f5a-8b68-6f4ca9941912'
$ClientId = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
$Endpoint = 'https://eops-acs.australia.communication.azure.com'
$Sender = 'hcl-elasticops@85f0f5ea-7143-4ae8-ba66-6bf624fe1fd4.azurecomm.net'
$MailSubject = 'JDE(IT) Azure Cloud Dashboard'
$ToRecipients = @(
  @{ address = 'DL-Cloud-JDE@hcltech.com'; displayName = 'DL-Cloud-JDE' },
  @{ address = 'eslam.mahmoud@jdecoffee.com'; displayName = 'Mahmoud, Eslam' },
  @{ address = 'farhan.malik@jdecoffee.com'; displayName = 'Malik, Farhan' },
  @{ address = 'ismetkursat.caliskan@jdecoffee.com'; displayName = 'Ismetkursat' }
)
$CcRecipients = @(
  @{ address = 'archana_maurya@hcltech.com'; displayName = 'Archana Maurya' },
  @{ address = 'sunidhi.kumari@hcltech.com'; displayName = 'Sunidhi Kumari' }
)

# OAuth token
$authority = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = @{
  grant_type = "client_credentials"
  client_id = $ClientId
  client_secret = Get-AutomationVariable -Name "client_secret"
  resource = 'https://communication.azure.com'
}

try {
  $tokenResponse = Invoke-WebRequest -Method POST -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
  $accessTokenObj = $tokenResponse.Content | ConvertFrom-Json
} catch {
  throw "Failed to acquire token: $_"
}
if (-not $accessTokenObj.access_token) { throw "No access_token returned." }

# Prepare email payload
$uuid = [guid]::NewGuid().ToString()
$gmt = Get-Date -Format U
$base64_html = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ReportFileName))
$payload = @{
  senderAddress = $Sender
  content = @{
    subject  = $MailSubject
    plainText = 'Azure Communication Service email (HTML attached).'
    html     = $script:htmlReport
  }
  recipients = @{
    to = $ToRecipients
    cc = $CcRecipients
  }
  attachments = @(
    @{
      name = $ReportFileName
      contentType = "text/html"
      contentInBase64 = $base64_html
    }
  )
} | ConvertTo-Json -Depth 100

$params = @{
  Method = 'POST'
  Uri = "$Endpoint/emails:send?api-version=2023-03-31"
  Headers = @{
    Authorization = "Bearer $($accessTokenObj.access_token)"
    'Content-Type' = 'application/json'
    'repeatability-first-sent' = $gmt
    'repeatability-request-id' = $uuid
  }
  Body = $payload
}
try {
  $sendResponse = Invoke-WebRequest @params -UseBasicParsing
  Write-Output "Email sent successfully. Response: $($sendResponse.StatusCode)"
} catch {
  throw "Email send failed: $_"
}
