#===========================
# ___ ___ _____ ___
#| _ \ _ \_  _/ __|
#|  _/   / | ||(_ |
#|_| |_|_\ |_|\___|
#    NETWORK MONITOR
#-------------------
# Description:    This script will iterate through the windows services that are set to automatic starting and alert
#                 if they don't. To aid in reviewing historical data, several counts of services are returned alongside
#                 an uptime count. There is also a grace period to avoid false alarms during boot up.
#
# Required Parameters: NOTE: these can be omitted if the 'Set placeholders as environment values' is enabled.
# -ComputerName: The name of the computer you want to check for its service (ip is okay too)
# -Username: The username and the domain/computer name that applies to the target hosts
# -Password: The password for the given user.
#
# Optional Parameters:
# -IgnoreList: The services that are ignored by the script (like google update services). Use * as wildcard. Note several
#                common offenders are excluded in the script, see $IgnoreHardcoded
# -StartupGrace: Override the grace period after startup, default of 600s. Note the official behavior of Windows is to start
#                Automatic (Delayed start) services 2 minutes after the last Automatic service starts, so on slow systems
#                this may require a longer delay.
#
# Example: 
# AdvancedAutomaticServicesCheck.ps1 -ComputerName %host -Username "%windowsdomain\%windowsuser" -Password "%windowspassword" -IgnoreList "Service1, Service2*"
# Values with % will be replaced by PRTG automatically.
#
# ------------------
# Adapted by Kevin White kwhite@gradea.ca, from 'Get-Services.ps1' by:
# (c) 2014 Stephan Linke | Paessler AG
#
#  Version 2.3 -- April 27,2017
#
param(
    [string]$ComputerName = "",
    [string]$UserName = "",
    [string]$Password = "",
    [string]$IgnoreList = "",
    [int]   $StartupGrace = 600 # NB: "Automatic (Delayed Start)" is actually 2 min after the last automatic service starts, so this seems like a safe default.
)


#confirm we have params or env's set for all req'd params
$paramErrors="";
if(!$ComputerName) {
    if(!$env:prtg_host) {
        $paramErrors += "ComputerName, ";
    } else {
        $ComputerName = $env:prtg_host
    }
}
if(!$UserName) {
    if(!$env:prtg_windowsuser) {
        $paramErrors += "UserName, ";
    } else {
        if(!$env:prtg_windowsdomain) {
            $UserName = $env:prtg_windowsuser
        } else {
            $UserName = $env:prtg_windowsdomain + "\" + $env:prtg_windowsuser
        }
    }
}
if(!$Password) {
    if(!$env:prtg_windowspassword) {
        $paramErrors += "Password, ";
    } else {
        $Password = $env:prtg_windowspassword
    }
}

#fix line wrap output on some old systems, see https://kb.paessler.com/en/topic/11163-how-to-avoid-line-breaks-for-powershell-custom-scripts-used-with-an-exe-script-sensor
$host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(512,50)

#error out if missing critical parameters
if($paramErrors) {
"<prtg>
    <error>1</error>
    <text>In the settings of this sensor, please set the 'Set placeholders as environment values', or add the following script parameter(s): "+$paramErrors.TrimEnd(", ")+".</text>
</prtg>
"
exit 0;
}

# Error if there's anything going on
$ErrorActionPreference = "Stop"

# Generate Credentials Object
$Credentials= New-Object System.Management.Automation.PSCredential ($UserName, (ConvertTo-SecureString $Password -AsPlainText -Force))

# hardcoded list that applies to all hosts
$IgnoreHardcoded = @('Google Update Service (gupdate)', 'Google Update', 'Dell Digital Delivery Service', 'VNC Server Version 4', 'Windows Modules Installer',
                    'Windows Biometric Service', 'Software Protection', 'Microsoft .NET Framework NGEN*', 'TPM Base Services', 'Windows Update', 'Remote Registry',
                    'Shell Hardware Detection', 'GoToAssist*', 'Performance Logs and Alerts', 'Windows Licensing Monitoring Service', 'Shell Hardware Detection', 
                    'Volume Shadow Copy', 'Microsoft Exchange Server Extension for Windows Server Backup', 'Manager für heruntergeladene Karten', 'Microsoft Exchange-Benachrichtigungsbroker',
                     'Remoteregistrierung', 'Windows-Biometriedienst', 'Gruppenrichtlinienclient', 'Übermittlungsoptimierung', 'Plattformdienst für verbundene Geräte',
                      'Citrix Remote Broker Provider', 'Dienst für die Benutzerzugriffsprotokollierung', 'Shellhardwareerkennung', 'DFS-Namespace', 'uvnc_service', 'TeamViewer 9',
                       'Volumeschattenkopie', 'Sophos Web Intelligence Update', 'Windows Installer', 'IGEL RMGUIServer', 'Sicherheitscenter', 'DCOM-Server-Prozessstart', 
                       'TPM-Basisdienste', 'Derby Database', 'Apache Tomcat 7', 'Kacheldaten-Modellserver', 'Microsoft Exchange EdgeSync', 'Windows-Bilderfassung (WIA)', 
                       'SQL Server-Agent*', 'WyBackupSvc', 'SQL Server Hilfsdienst*' ,' SQL Active Directory Helper Service', 'MDM Integration Service', 'wdPostMan',
                        'Z-Cron', 'Downloaded Maps Manager', 'RIB NetCounterLM', 'Intelligenter Hintergrundï¿½bertragungsdienst', 'Smartcard', 'Windows Agent Service', 'Multimediaklassenplaner')

# NB: the weird "| ? {$_}" is to remove empty array elements
$Ignore = ((@($IgnoreList -Split ",") + $IgnoreHardcoded) | ? {$_}  | foreach { [Regex]::Escape($_.trim()) -replace "\*", ".*" } ) -join "|"

Try { 
    $All_Services = Get-WmiObject Win32_Service -ComputerName $ComputerName -Credential $Credentials
    $wmi_os = gwmi Win32_OperatingSystem -ComputerName $ComputerName -Credential $Credentials 
} Catch { # If the script runs for the PRTG probe server itself, we don't need credentials, lets try w/o creds
    Try {
        $All_Services = Get-WmiObject Win32_Service -ComputerName $ComputerName
        $wmi_os = gwmi Win32_OperatingSystem -ComputerName $ComputerName 
    } Catch {
        
    "<prtg>
    <error>1</error>
    <text>Error: could not connect to host `"$ComputerName`". " + $Error[0].Exception.Message + ".</text>
    </prtg>
    "
    exit 0;
    }
}

$FilteredServices = $All_Services | Where {$_.DisplayName -notmatch $Ignore} 
$ServicesFilteredOut = $All_Services | Where {$_.DisplayName -match $Ignore} 

$UptimeSeconds = ([int](New-TimeSpan $wmi_os.ConvertToDateTime($wmi_os.Lastbootuptime) $(get-date)).TotalSeconds)

$Services = $FilteredServices | Where {$_.StartMode -eq 'Auto' -and $_.State -ne 'Running'}  
$NotRunningServices = ($FilteredServices | Where {$_.StartMode -eq 'Auto' -and $_.State -ne 'Running'})

$importpath = "C:\PRTG\Sensordata\$computername.xml"
try {
    winrm set winrm/config/client ‘@{TrustedHosts="*"}’
}
catch {
    
}
#Versuche Dienst einmal zu starten
if(Test-Path $importpath){
$importedservices = Import-Clixml -Path $importpath
}

    ForEach($Service in $NotRunningServices)
    {   
        if ($importedservices -notcontains $Service) { 
        try {
            $command = {$service = $args[0] 
            $Service | Start-Service
        }
            Invoke-Command -ComputerName $ComputerName -Credential $Credentials -ScriptBlock $command -ArgumentList $Service
        }
        catch {
            $services_not_restartable += $Service
            $_.Exception.Message
           
        }
    }
        
    }

    if (Test-Path $importpath) {
        Remove-Item $importpath
    }
    
    if ($services_not_restartable -ne '')
    {$services_not_restartable | Export-Clixml -Path $importpath -Force}



"<prtg>
    <result>
        <channel>Total Services</channel>
        <unit>Count</unit>
        <value>" + ($FilteredServices | measure).Count + "</value>
        <unit>Count</unit>
        <FLOAT>0</FLOAT>
    </result>
    <result>
        <channel>Total Services Started</channel>
        <value>" + ($FilteredServices | Where { $_.State -eq 'Running' } | measure).Count + "</value>
        <unit>Count</unit>
        <FLOAT>0</FLOAT>
    </result>
    <result>
        <channel>Total Automatic (and Delayed) Services</channel>
        <value>" + ($FilteredServices | Where { $_.StartMode -eq 'Auto' }  | measure).Count + "</value>
        <FLOAT>0</FLOAT>
        <unit>Count</unit>
    </result>
    <result>
        <channel>Total Automatic (and Delayed) Services Started</channel>
        <value>" + ($FilteredServices | Where { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }  | measure).Count + "</value>
        <FLOAT>0</FLOAT>
        <unit>Count</unit>
    </result>
    <result>
        <channel>Total Automatic (and Delayed) Services NOT Started</channel>
        <value>" + ($FilteredServices | Where { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' }  | measure).Count + "</value>
        <FLOAT>0</FLOAT>
        <unit>Count</unit>
    </result>"

if(($FilteredServices | Where { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' }  | measure).Count -ge 1) {
    #At least 1 service is not running, issue warning or error
    $NotRunningServices = ($FilteredServices | Where {$_.StartMode -eq 'Auto' -and $_.State -ne 'Running'} | Select -expand DisplayName) -join ", "
    if($UptimeSeconds -lt $StartupGrace) {
        "<Warning>1</Warning>
        <Text>Grace period remaining: "+($StartupGrace - $UptimeSeconds)+"s; Automatic services not running: " + $NotRunningServices + "</Text>"
    } else {
        "<Error>1</Error>
        <Text>Automatic services not running: " + $NotRunningServices + "</Text>"
    }
}
"   <result>
        <channel>Uptime</channel>" #useful to see when there is a grace period for startup in graphs
        "<value>$UptimeSeconds</value>
        <FLOAT>0</FLOAT>
        <unit>TimeSeconds</unit>
    </result>
    <result>
        <channel>Total Services Excluded by Filter</channel>
        <value>" + ($ServicesFilteredOut | Measure-Object).Count + "</value>
        <FLOAT>0</FLOAT>
        <unit>Count</unit>
    </result>
</prtg>"