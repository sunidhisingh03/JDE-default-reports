Connect-AzAccount -Identity
Function FreeSpaceCSVforLinux {
$Script:fslindata1 = @()
$subs = Get-AzSubscription
foreach($sub in $subs){
Set-AzContext -Subscription $sub.id
$workspaces = Get-AzOperationalInsightsWorkspace 
 
  foreach($workspace in $workspaces){
    $query1 = @"
            Perf
| where TimeGenerated > ago(30d)
| where ObjectName == 'Logical Disk' and CounterName == '% Used Space' and InstanceName !hasprefix "/snap" and InstanceName !hasprefix "/run" and InstanceName !hasprefix "/sys"
| where isempty(_ResourceId) == false
| summarize Average_fslin = avg(100 - CounterValue) by Computer, _ResourceId, InstanceName
| extend SubscriptionId = tostring(split(_ResourceId, "/")[2]), Target_ResourceGroup = tostring(split(_ResourceId, "/")[4])
| project Computer, SubscriptionId, Target_ResourceGroup, Average_fslin, InstanceName
"@
$runQuery = Invoke-AzOperationalInsightsQuery -Workspace $workspace -Query $query1
$queryResults = $runQuery.Results
foreach($queryResult in $queryResults){
    write-host  $queryResult.Computer
    write-host  $queryResult.Computer.Split(".")[0]
    write-host  $queryResult
 
$subname = (Get-Azsubscription -SubscriptionId $queryResult.SubscriptionId).Name
$dataRow = [pscustomobject]@{
                       "Virtual Machine" =  $queryResult.Computer
                       "Subscription Name" =   $subname   
                       "ResourceGroupName" = $queryResult.Target_ResourceGroup
                       "Disk" = $queryResult.InstanceName
                       "LogAnalyticsWorkSpace"= $workspace.Name
                       "CounterValue" = [math]::Round($queryResult.Average_fslin,2)
                       
                 }
              
         $Script:fslindata1 +=$dataRow
        }
     $Script:fslindata1 | Export-Csv -Path "Logical Disk Free Space for Linux Output.csv" -Force -NoTypeInformation -Encoding UTF8

      }
     }

 }


 Function Top20FreeSpaceforLinux{
    try{
    $data123 = @()
    $dataRow = @()
    $Path = "./Logical Disk Free Space for Linux Output.csv"
     $Computer = @()
     $Subscription = @()
     $CounterValue = @()
     $instanceName = @()
      $Subscription = @()
      $res = @()
      $law =@()
     $size1 = @()
    Import-csv -Path $Path | ForEach-Object{
        $Subscription += $_.'Subscription Name'
        $Computer += $_.'Virtual Machine'
        $CounterValue += [int]$_.'CounterValue'
        $size1 += $_.'CounterValue'
        $instanceName += $_.'Disk'
        $res  += $_.'ResourceGroupName'
        $law += $_.'LogAnalyticsWorkSpace'
        
    
        }
    
        for($i=0;$i -lt $CounterValue.count;$i++){
          for($j = $i+1; $j -lt $CounterValue.count ; ++$j){
    
             if($CounterValue[$i] -lt $CounterValue[$j]){
    
                $temp = $Subscription[$i]
                $Subscription[$i] = $Subscription[$j]
                $Subscription[$j] = $temp

                $temp = $instanceName[$i]
                $instanceName[$i] = $instanceName[$j]
                $instanceName[$j] = $temp
    
                $temp = $CounterValue[$i]
                $CounterValue[$i] = $CounterValue[$j]
                $CounterValue[$j] = $temp
    
                $temp = $Computer[$i]
                $Computer[$i] = $Computer[$j]
                $Computer[$j] = $temp
    
                $temp = $size1[$i]
                $size1[$i] = $size1[$j]
                $size1[$j] = $temp
                
                $temp = $res[$i]
                $res[$i] = $res[$j]
                $res[$j] = $temp

                $temp = $law[$i]
                $law[$i] = $law[$j]
                $law[$j] = $temp
             
             }
           }
        
        }
    
    
         for($i=0; $i -lt 17;++$i){
    
         Write-Output $Subscription[$i]
         Write-Output $Computer[$i]
         Write-Output $res[$i]
         Write-Output $instanceName[$i]
         Write-Output $law[$i]
         Write-Output $size1[$i]
         
         if([int]$size1[$i] -le 10){
            $dataRow +=  "
        <tr> 
           <td>$($Subscription[$i])</td> 
           <td>$($Computer[$i])</td> 
           <td>$($res[$i])</td> 
           <td Style= 'text-align: Center'>$($instanceName[$i])</td> 
           <td>$($law[$i])</td> 
           <td Style='background-color: #ffbf00'; align = 'Center'>$($size1[$i])</td> 

        
         </tr>
        
      "   
      }
      
     else{
         $dataRow += "
            <tr> 
              <td>$($Subscription[$i])</td> 
              <td>$($Computer[$i])</td> 
              <td>$($res[$i])</td>
              <td Style= 'text-align: Center'>$($instanceName[$i])</td>  
              <td>$($law[$i])</td> 
              <td Style='background-color: #ccffcc'; align = 'Center'>$($size1[$i])</td> 
           </tr>
                 "
      }
     
                
            }
    
            $Script:data123+=$dataRow
        }
        catch{
         $errorCSV = "Error while creating Top 20 Used Space report - $($error[0])"
         Write-Output $errorCSV "85"
     
        
        }
      }


      Function Bottom20FreeSpaceforLinux{
        try{
        $data1234 = @()
        $dataRow = @()
        $Path = "./Logical Disk Free Space for Linux Output.csv"
         $Computer = @()
         $Subscription = @()
         $instanceName = @()
         $CounterValue = @()
          $Subscription = @()
          $res = @()
         $law =@()
         $size1 = @()
        Import-csv -Path $Path | ForEach-Object{
            $Subscription += $_.'Subscription Name'
            $instanceName += $_.'Disk'
            $Computer += $_.'Virtual Machine'
            $CounterValue += [int]$_.'CounterValue'
            $size1 += $_.'CounterValue'
            $res  += $_.'ResourceGroupName'
            $law += $_.'LogAnalyticsWorkSpace'
          
            }
        
            for($i=0;$i -lt $CounterValue.count;$i++){
              for($j = $i+1; $j -lt $CounterValue.count ; ++$j){
        
                 if($CounterValue[$i] -gt $CounterValue[$j]){
        
                    $temp = $Subscription[$i]
                    $Subscription[$i] = $Subscription[$j]
                    $Subscription[$j] = $temp

                    $temp = $instanceName[$i]
                    $instanceName[$i] = $instanceName[$j]
                    $instanceName[$j] = $temp
        
                    $temp = $CounterValue[$i]
                    $CounterValue[$i] = $CounterValue[$j]
                    $CounterValue[$j] = $temp
        
                    $temp = $Computer[$i]
                    $Computer[$i] = $Computer[$j]
                    $Computer[$j] = $temp
        
                    $temp = $size1[$i]
                    $size1[$i] = $size1[$j]
                    $size1[$j] = $temp

                    $temp = $res[$i]
                    $res[$i] = $res[$j]
                    $res[$j] = $temp

                    $temp = $law[$i]
                    $law[$i] = $law[$j]
                    $law[$j] = $temp
        
                 
                 }
               }
            
            }
        
        
             for($i=0; $i -lt 20;++$i){
        
             Write-Output $Subscription[$i]
             Write-Output $Computer[$i]
             Write-Output $res[$i]
             Write-Output $instanceName[$i]
             Write-Output $law[$i]
             Write-Output $size1[$i]
            
             
             
             if([int]$size1[$i] -le 10){
                $dataRow +=  "
            <tr> 
               <td>$($Subscription[$i])</td> 
               <td>$($Computer[$i])</td> 
               <td>$($res[$i])</td> 
               <td Style= 'text-align: Center'>$($instanceName[$i])</td> 
               <td>$($law[$i])</td> 
               <td Style='background-color: #ffbf00'; align = 'Center'>$($size1[$i])</td> 
    
            
             </tr>
            
          "   
          }
          
         else{
             $dataRow += "
                <tr> 
                  <td>$($Subscription[$i])</td> 
                  <td>$($Computer[$i])</td> 
                  <td>$($res[$i])</td>
                  <td Style= 'text-align: Center'>$($instanceName[$i])</td>  
                  <td>$($law[$i])</td> 
                  <td Style='background-color: #ccffcc'; align = 'Center'>$($size1[$i])</td> 
               </tr>
                     "
          }
         
       }
    $Script:data1234+=$dataRow
        

            }
            catch{
             $errorCSV = "Error while creating Bottom 20 Used Space report - $($error[0])"
             Write-Output $errorCSV "85"
         
            
            }
          }

Write-Output "Fetching Free Space CSV for Linux  Data"
FreeSpaceCSVforLinux

Write-Output "Fetching Top 20 Free Space CSV for Linux  Data"
Top20FreeSpaceforLinux

Write-Output "Fetching Bottom 20 Free Space CSV for Linux Data"
Bottom20FreeSpaceforLinux

$htmlReport1 = $null
$script:htmlReport1 = " 

    <html> 
    
    <head>
    <style>{font-family: sans-serif; font-size: 10pt;}
    TABLE{border: 1px solid black; border-collapse: collapse; font-size:13pt;width: 100%;}
    TH{border: 1px solid white; font-size: 10pt;background-color: rgb(55, 124, 159); padding: 5px; color: white;}
    TD{border: 1px solid black; font-size: 10pt;padding: 5px; }
    body{background-color: #ffffff;}
    h2{background-color: rgb(55, 124, 159); color: #ffffff;text-align: center;}
    p{background-color: #ffffff;}
    h3{background-color: rgb(55, 124, 159); color: #ffffff;text-align: center;}
</style>
    </head>
    <body> 

                <h2>Top 20 Linux - Disk Free Space Report</h2> 

                <table> 

                <tr><th Style = 'text-align: left'>Subscription Name</th><th Style = 'text-align: left'>Virtual Machine</th><th Style = 'text-align: left'>ResourceGroupName</th><th Style= align = 'Center'>Disk</th><th Style = 'text-align: left'>LogAnalyticsWorkSpace</th><th>Counter Value (In Percentage)</th>

                </tr> 

                $Script:data123

                </table> 

                <h2>Bottom 20 Linux - Disk Free Space Report</h2> 

                <table> 

                <tr><th Style = 'text-align: left'>Subscription Name</th><th Style = 'text-align: left'>Virtual Machine</th><th Style = 'text-align: left'>ResourceGroupName</th><th Style= align = 'Center'>Disk</th><th Style = 'text-align: left'>LogAnalyticsWorkSpace</th><th>Counter Value (In Percentage)</th>

                </tr> 

                $Script:data1234

                </table> 

                <h3>Developed By - Elastic Ops Autonomics</h3> 

    </body> 

    </html> 

     

"


$htmlPath = "Logical Disk Free Space for Linux HTML.html"
$htmlReport | Out-File $htmlPath -Force

# Upload both CSV and HTML to Azure Blob
$storageAccountName = "statm4finopsdatatstwe001"
$containerName = "finops-data"
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

# Upload CSV
$csvPath = "Logical Disk Free Space for Linux Output.csv"
$csvBlobName = [System.IO.Path]::GetFileName($csvPath)
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false
Write-Output "CSV report uploaded to Azure Storage container '$containerName' as '$csvBlobName'."

# Upload HTML
$htmlBlobName = [System.IO.Path]::GetFileName($htmlPath)
Set-AzStorageBlobContent -File $csvPath -Container $containerName -Blob $blobName -Context $ctx -Force -Confirm:$false
Write-Output "HTML report uploaded to Azure Storage container '$containerName' as '$htmlBlobName'."