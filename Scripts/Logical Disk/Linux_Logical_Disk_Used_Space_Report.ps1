Connect-AzAccount -Identity
 Function UsedSpaceCSVforLinux {
  $Script:uslindata1 = @()
$subs = Get-AzSubscription
foreach($sub in $subs){
Set-AzContext -Subscription $sub.id
$workspaces = Get-AzOperationalInsightsWorkspace 
 
  foreach($workspace in $workspaces){
    $query1 = @"
            Perf
| where TimeGenerated > ago(7d)
| where ObjectName == 'Logical Disk' and CounterName == '% Used Space' and InstanceName !hasprefix "/snap" and InstanceName !hasprefix "/run" and InstanceName !hasprefix "/sys"
| where isempty(_ResourceId) == false
| summarize Average_uslin = avg(CounterValue) by Computer, _ResourceId, InstanceName
| extend SubscriptionId = tostring(split(_ResourceId, "/")[2]), Target_ResourceGroup = tostring(split(_ResourceId, "/")[4])
| project Computer, SubscriptionId, Target_ResourceGroup, Average_uslin, InstanceName
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
                       "CounterValue" = [math]::Round($queryResult.Average_uslin,2)
                       
                 }
              
         $Script:uslindata1 +=$dataRow
        }
    $Script:uslindata1 | Export-Csv -Path "Logical Disk Used Space for Linux Output.csv" -Force -NoTypeInformation -Encoding UTF8
      }
     }

 }

 Function Top20UsedSpaceforLinux{
    try{
    $data123 = @()
    $dataRow = @()
    $Path = "./Logical Disk Used Space for Linux Output.csv"
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
    
    
         for($i=0; $i -lt 20;++$i){
    
         Write-Output $Subscription[$i]
         Write-Output $Computer[$i]
         Write-Output $res[$i]
         Write-Output $instanceName[$i]
         Write-Output $law[$i]
         Write-Output $size1[$i]
         
         if([int]$size1[$i] -gt 95){
            $dataRow +=  "
        <tr> 
           <td>$($Subscription[$i])</td> 
           <td>$($Computer[$i])</td> 
           <td>$($res[$i])</td> 
           <td Style= 'text-align: Center'>$($instanceName[$i])</td> 
           <td>$($law[$i])</td> 
           <td Style='background-color: #ffc2b3'; align = 'Center'>$($size1[$i])</td> 

        
         </tr>
        
      "   
      }
      elseif(([int]$size1[$i] -ge 85) -and ([int]$size1[$i] -le 95)){
        $dataRow += "
            <tr> 
              <td>$($Subscription[$i])</td> 
              <td>$($Computer[$i])</td> 
              <td>$($res[$i])</td>
              <td Style= 'text-align: Center'>$($instanceName[$i])</td>  
              <td>$($law[$i])</td> 
              <td Style='background-color:  #ffbf00'; align = 'Center'>$($size1[$i])</td> 
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


      Function Bottom20UsedSpaceforLinux{
        try{
        $data1234 = @()
        $dataRow = @()
        $Path = "./Logical Disk Used Space for Linux Output.csv"
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
            
             
             
             if([int]$size1[$i] -gt 95){
                $dataRow +=  "
            <tr> 
               <td>$($Subscription[$i])</td> 
               <td>$($Computer[$i])</td> 
               <td>$($res[$i])</td> 
               <td Style= 'text-align: Center'>$($instanceName[$i])</td> 
               <td>$($law[$i])</td> 
               <td Style='background-color: #ffc2b3'; align = 'Center'>$($size1[$i])</td> 
    
            
             </tr>
            
          "   
          }
          elseif(([int]$size1[$i] -ge 85) -and ([int]$size1[$i] -le 95)){
            $dataRow += "
                <tr> 
                  <td>$($Subscription[$i])</td> 
                  <td>$($Computer[$i])</td> 
                  <td>$($res[$i])</td>
                  <td Style= 'text-align: Center'>$($instanceName[$i])</td>  
                  <td>$($law[$i])</td> 
                  <td Style='background-color:  #ffbf00'; align = 'Center'>$($size1[$i])</td> 
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

Write-Output "Fetching Used Space CSV for Linux  Data"
UsedSpaceCSVforLinux 

Write-Output "Fetching Top 20 Used Space CSV for Linux  Data"
Top20UsedSpaceforLinux

Write-Output "Fetching Bottom 20 Used Space CSV for Linux Data"
Bottom20UsedSpaceforLinux

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

                <h2>Top 20 Linux - Disk Utilization Report</h2> 

                <table> 

                <tr><th Style = 'text-align: left'>Subscription Name</th><th Style = 'text-align: left'>Virtual Machine</th><th Style = 'text-align: left'>ResourceGroupName</th><th Style= align = 'Center'>Disk</th><th Style = 'text-align: left'>LogAnalyticsWorkSpace</th><th>Counter Value (Consumed In Percentage)</th>

                </tr> 

                $Script:data123

                </table> 

                <h2>Bottom 20 Linux - Disk Utilization Report</h2> 

                <table> 

                <tr><th Style = 'text-align: left'>Subscription Name</th><th Style = 'text-align: left'>Virtual Machine</th><th Style = 'text-align: left'>ResourceGroupName</th><th Style= align = 'Center'>Disk</th><th Style = 'text-align: left'>LogAnalyticsWorkSpace</th><th>Counter Value (Consumed In Percentage)</th>

                </tr> 

                $Script:data1234

                </table> 

                <h3>Developed By - Elastic Ops Autonomics</h3> 

    </body> 

    </html> 

     

"


$htmlReport1 | Out-File "Logical Disk Used Space for Linux HTML.html" -Force

$fileName = "Logical Disk Used Space for Linux Output.csv"
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
$base64_csv = [Convert]::ToBase64String([IO.File]::ReadAllBytes($($fileName)))
 
 
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
            Subject = 'JDE(IT) | Azure | Linux Logical Disk Used Space'
            PlainText = 'used azure communication service'
            html = "$($htmlReport1)"
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
 
