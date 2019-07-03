$scriptblock={

$avhd_Count = $null
$prtgoutput = $null


$avhd_Count = (Get-ChildItem -File C:\ClusterStorage -Recurse  |Where-Object {$_.Extension -like ".avhdx"} | Measure-Object).count

$prtgoutput += "<result>
               <channel>Anzahl AVHDs</channel>
               <value>$avhd_Count</value>
               <LimitMaxError>10</LimitMaxError>
               <LimitMode>1</LimitMode>
               </result>"

$prtgoutput



}

$ComputerName = $env:prtg_host

$prtgoutput = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptblock

Write-Output "<prtg>" $prtgoutput "</prtg>"
