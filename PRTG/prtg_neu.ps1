function Add-3cxCloudDevice {
    param (
        $company, $Name, $IPAddress, $WindowsUserName, $WindowsPassword
    )

    $Name = $Name + " (" + $IPAddress + ")"

    $NewGroup = Get-Group "3CX Cloud*" | Add-Group $company

    $NewDevice = get-device "unimavs01*" | Clone-Object -DestinationId ($NewGroup).Id $Name $IPAddress

    $NewDevice | Set-ObjectProperty -WindowsUserName $WindowsUserName -WindowsPassword $WindowsPassword

    $NewDevice | Resume-Object
}

function Add-Device-alu {
    param (
        $company, $Name, $IPAddress, $vorlage
    )

    $Name = $Name + " (" + $IPAddress + ")"

    if($null -eq $vorlage)
    {
        $vorlage1 = "ITS-WindowsServer"
    }
    elseif ($vorlage -like "ping") {
            $vorlage1 = "ITS-Ping"         
        }

        $template = Get-DeviceTemplate $vorlage1

    $Probe = Get-Probe *$company*

    
    $NewDevice = $Probe | Add-Device $Name

    $NewDevice | Set-ObjectProperty -Hostv4 $IPAddress

    $NewDevice | Resume-Object

    Start-Sleep -Seconds 1

    $NewDevice | Start-AutoDiscovery $template

    $NewDevice

    Start-Sleep -Seconds 15

    $NewDevice | set-ObjectProperty -Name $Name
}

function Add-Device-csv {
    param (
        $company, $csv, $vorlage, $group
    )
    $CreatedDevices = @()
    $Names = @()

    foreach($device in $csv)
    {
    $Name = $device.Name
    $IPAddress = $device."IPAddress"
    $Name = $Name + " (" + $IPAddress + ")"

    $Probe = Get-Probe *$company*

    if($null -eq $vorlage)
    {
        $vorlage1 = "ITS-WindowsServer"
    }
    elseif ($vorlage -like "ping") {
            $vorlage1 = "ITS-Ping"         
        }

$location = $Probe

    if($null -ne $group)
    {
        $group1 = Get-Group *$group
        if ($null -ne $probe) {
            $group1 = $Probe | Get-Group *$group
        }
        
       if($null -eq $group1)
       {
            $location = $Probe | Add-Group $group
       }
       else {
           $location = $group1
       }
    }


    $template = Get-DeviceTemplate $vorlage1

  
    $NewDevice = $location | Add-Device $Name

    $NewDevice | Set-ObjectProperty -Hostv4 $IPAddress

    $NewDevice | Resume-Object

    #Start-Sleep -Seconds 5

    $NewDevice | Start-AutoDiscovery $template
    $NewDevice | Set-ObjectProperty -Name $Name
    $CreatedDevices += $NewDevice
    $NewDevice
    }

    #sleep10
   # foreach($device in $CreatedDevices)
   # {$device | Set-ObjectProperty -Name $Name}
}

#$csv = import-csv H:\Zwicky\switch.csv
#Add-Device-csv zwicky $csv ping Netzwerk

function ReplaceService {
    param (
        
    )

    #test
    #$sensors = get-probe "Flawa"  |  Get-Sensor -Tag wmiservicesensor

    $sensors = Get-Sensor -Tag wmiservicesensor
    $dienst = (get-sensor "Automatische Dienste*" -Count 1)


    foreach($sensor in $sensors)
    {
        if($sensor.status -notlike "paused")
        {
        if($sensor.Probe -notlike "Steinemann AG" )
        {

        $device = get-device -id $sensor.parentId

        $device_automatic_sensor = $device | Get-Sensor "Automatische Dienste*" 

        if($null -eq $device_automatic_sensor)
        {
            $newsensor = $dienst | Clone-Object -DestinationId $device.id
            $newsensor | Resume-Object
        }
        $sensor | Remove-Object -force
        Write-Host "Sensor Geloescht" $sensor.Probe $sensor.Device $sensor. $sensor
        }
        }
    }
   
    
}

#Probe vorne beim Probename wegmachen.
function Rename-Probes {
    param (
        
    )

    $probes = Get-Probe Probe*
foreach ($probe in $probes)
{
    $name = $probe.name.TrimStart('Probe ')
    $probe | Rename-Object $name

    
}
}

#Rename-Probes

#ReplaceService

function Set-MSA-Timeout {
    param (
        #$device = "BAGMSA01 Controller B*"
    )
    $sensors = Get-Sensor -Tags sshsan

   
   
   
    $sensors |  Set-ObjectProperty -Property Timeout -Value 300

    $sensors |  Set-ObjectProperty -Property Interval -Value "00:30:00"
    
    $sensors | set-ObjectProperty -RawProperty timeout_ -RawValue 300 -Force
    $sensors | set-ObjectProperty -RawProperty shelltimeou_ -RawValue 300 -Force

    $sensors | Get-ObjectProperty -Property Timeout
    $sensors | Get-ObjectProperty -RawProperty timeout_
    $sensors | Get-ObjectProperty -RawProperty shelltimeout_
    $sensors | Get-ObjectProperty -Property Interval
    
}



#Add-Device-csv -company Hardegger -csv 'H:\Hardegger Käse\switch.csv' -vorlage ping -group "Netzwerk-Infrastruktur"
#Get-Sensor -Tags sshsan | where {$_.Message -eq "Timeout while trying to aquire Mutex, try to use bigger Scanningintervals"} | Acknowledge-Sensor -Forever

#Get-Sensor -Status Paused | where {$_.probe -notlike "Stein*" -and $_.probe -notlike "RNO*" }
#(Get-Sensor -Status Paused | where {$_.probe -notlike "Stein*" -and $_.probe -notlike "RNO*" } | select name, probe,Device, lastup | sort lastup).count
#$devices = get-site zuhause* | Get-Devices -Devicetype 'Server'

#Get-Device -id 27760 | Get-Sensor | where {$_.name -like "Disk*"} | Remove-Object -Force

#Get-Sensor -Tags systemhealthsensor | Remove-Object -Force
#Get-Sensor -Tags commonsaas | Remove-Object -Force

<#$sensor = get-sensor -id 36722
$channel = $sensor | Get-Channel -Name "Gesamt" 
$channel | Set-ChannelProperty UpperErrorLimit 95
$channel | Set-ChannelProperty UpperWarningLimit 90
$channel | Set-ChannelProperty LimitsEnabled "true"


$sensor = get-sensor -id 36721
$channel = $sensor | Get-Channel -Name "Verfügbarer Speicher in Prozent" 
$channel | Set-ChannelProperty LowerErrorLimit 5
$channel | Set-ChannelProperty LowerWarningLimit 10
$channel | Set-ChannelProperty  LimitsEnabled "true"

$sensors =  Get-Sensor -Tags "wmimemorysensor"
foreach ($sensor in $sensors)
{
    $channel = $sensor | Get-Channel -Name "Verfügbarer Speicher in Prozent" 
    $channel | Set-ChannelProperty LowerErrorLimit 5
    $channel | Set-ChannelProperty LowerWarningLimit 10
    $channel | Set-ChannelProperty  LimitsEnabled "true"
    Write-Host $sensor.Name
}
#>

#Add-Device-csv -company "Büchler" -csv $csv -group "B*chler*"