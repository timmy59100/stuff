<#
.DESCRIPTION
This script is intended to be used with PRTG Network Monitor (as a custom "EXE/Script Advanced" sensor).
It will return the difference in minutes between the current date and the last time each VM replicated from
Primary to the Replica server.

Please make sure that the windows credential (domain user) used in PRTG (on this sensor) is a member
of the local group "Hyper-V Administrators" on the target Hyper-V servers. This is the only way, unfortunately.
Due to Hyper-V limitations, it is not possible do delegate "only read access" or something like this.

Some values are hard-coded: the script will consider 20 minutes as a limit for a "Normal" replication state and it
will trigger a "warning" alert (yellow) if any VM returns a value above said limit. The max value considered is 59 minutes,
over which the sensor will trigger an "error" alert (red). The script will not return values above 60 minutes. After that,
you can refer to the "Downtime" informed by PRTG (Down since X days, Y hours, etc).
#>

# Please provide the Hyper-V servers on the following line (replace by actual values):

param(
    [string]$ComputerName = "192.168.150.20",
    [string]$UserName = "hv01\administrator",
    [string]$Password = "vivorsorge`$15"
)

$ErrorActionPreference = "Stop"

# Generate Credentials Object
$SecPasswd  = ConvertTo-SecureString $Password -AsPlainText -Force
$Credentials= New-Object System.Management.Automation.PSCredential ($UserName, $secpasswd)

Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
$CurrentDate = (Get-Date)
$Results = Get-VMReplication | Select VMName, VMId, ReplicationMode, ReplicationHealth, ComputerName,`
                                                PrimaryServer, ReplicaServer, LastReplicationTime, ReplicationState `
                                                | Where-Object ReplicationMode -eq "Primary"
$xmlstring = "<?xml version=`"1.0`"?>`n    <prtg>`n"

ForEach ($eachresult IN $Results) {

        if($eachresult.ReplicationState -eq "InitialReplicationInProgress" -or $eachresult.LastReplicationTime -eq $null){
            if($eachresult.ReplicationState -eq "InitialReplicationInProgress"){$xmlstring += "<text>Initial Replication In Progress</text>`n"}
            $xmlstring += "    <result>`n"
            $xmlstring += "        <channel>$($eachresult.VMname)</channel>`n"
            $xmlstring += "        <unit>Custom</unit>`n"
            $xmlstring += "        <CustomUnit>min</CustomUnit>`n"
            $xmlstring += "        <mode>Absolute</mode>`n"
            $xmlstring += "        <showChart>1</showChart>`n"
            $xmlstring += "        <showTable>1</showTable>`n"
            $xmlstring += "        <float>0</float>`n"
            $xmlstring += "        <value>99</value>`n"
            $xmlstring += "        <LimitMaxError>59</LimitMaxError>`n"
            $xmlstring += "        <LimitMaxWarning>20</LimitMaxWarning>`n"
            $xmlstring += "        <LimitWarningMsg>Hyper-V Replication for this VM is in Warning state</LimitWarningMsg>`n"
            $xmlstring += "        <LimitErrorMsg>Hyper-V Replication failed for this VM and is in Critical state</LimitErrorMsg>`n"
            $xmlstring += "        <LimitMode>1</LimitMode>`n"
            $xmlstring += "    </result>`n"
        }else{
            $TotalMinutes = (New-Timespan –Start ($eachresult.LastReplicationTime) –End $CurrentDate).TotalMinutes
            $xmlstring += "    <result>`n"
            $xmlstring += "        <channel>$($eachresult.VMname)</channel>`n"
            $xmlstring += "        <unit>Custom</unit>`n"
            $xmlstring += "        <CustomUnit>min</CustomUnit>`n"
            $xmlstring += "        <mode>Absolute</mode>`n"
            $xmlstring += "        <showChart>1</showChart>`n"
            $xmlstring += "        <showTable>1</showTable>`n"
            $xmlstring += "        <float>0</float>`n"
            $xmlstring += "        <value>$(IF ($TotalMinutes -lt 1) {"0"} ELSE {IF ($TotalMinutes -le 60) {$TotalMinutes.ToString("#")} ELSE {"60"}})</value>`n"
            $xmlstring += "        <LimitMaxError>59</LimitMaxError>`n"
            $xmlstring += "        <LimitMaxWarning>20</LimitMaxWarning>`n"
            $xmlstring += "        <LimitWarningMsg>Hyper-V Replication for this VM is in Warning state</LimitWarningMsg>`n"
            $xmlstring += "        <LimitErrorMsg>Hyper-V Replication failed for this VM and is in Critical state</LimitErrorMsg>`n"
            $xmlstring += "        <LimitMode>1</LimitMode>`n"
            $xmlstring += "    </result>`n"
        }
    }
    $xmlstring += "    </prtg>"
    Write-Host $xmlstring
 } -credential $Credentials


