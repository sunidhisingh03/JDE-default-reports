# Create resource group and storage account in the subscription
$SubName = 'EOPS-lab'
$RGName = "rg-finops-prd-we-001" 
$location = "Central India"
#$storageAccountName = "statm4finopsdatatstwe001"

$Sub = Get-AzSubscription -SubscriptionName $SubName
Set-AzContext -Subscription $Sub.Id

New-AzResourceGroup -Name $RGName -Location $location -Tag @{application_id ="app000000";application_name="hcltools";environment_type="prd";business_capability="operations";business_impact="high";opco="0002"}

#New-AzStorageAccount -Name $storageAccountName -ResourceGroupName $RGName -SkuName "Standard_LRS" -Location $location
# $storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $RGName -AccountName $storageAccountName).Value[0]
# $ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
# New-AzStorageContainer -Name "finops-data" -Context $ctx