param(
    [string]$IgnoreList = ""
)

$keyfilePassword = $env:prtg_linuxpassword  | ConvertTo-SecureString -asPlainText -Force
$username = "root"
$ComputerName = $env:prtg_host 
$keyfile = "C:\PRTG\$Computername"
$command = "/usr/local/bin/confd-client.plx get_ipsec_status|grep 'REF_\|all_established'"



$credential = New-Object System.Management.Automation.PSCredential($username,$keyfilePassword)
$session = New-SSHSession -ComputerName $ComputerName -KeyFile $keyfile -Credential $credential -Force -WarningAction SilentlyContinue
$ssh = Invoke-SSHCommand -Index 0 -Command $command

$Ignore = (@($IgnoreList -Split ",") | ? {$_}  | foreach { [Regex]::Escape($_.trim()) -replace "\*", ".*" } ) -join "|"

function add-Channel {
    param (
        $channelname,
        $channelvalue
    )
    if($channelvalue -eq 0){$warning = 1}else{$warning = 0}

    $channel = "
    <result>
        <channel>" + $channelname + "</channel>
    " + "   <unit>Status</unit>
        <value>" + $channelvalue + "</value>
        <ValueLookup>prtg.standardlookups.boolean.statetrueok</ValueLookup>
    </result>"

    $channel
}
$prtg = "<prtg>"

$counter = 0
foreach($string in $ssh.output)
    {
        if ($string -match '0') {
            $result = 0
        }
        elseif ($string -match '1') {
            $result = 1
        }
        else {
            $result = $string.replace("          'REF_IpsSit", '')
            $result = $result.replace("' => {", '')
        }
        if($counter % 2) {
            $vpn_status = $result
            if($Ignore -like "")
            {
                $prtg += add-Channel -channelname $vpn_name -channelvalue $vpn_status
            }
            elseif($vpn_name -notmatch $Ignore)
            {
            $prtg += add-Channel -channelname $vpn_name -channelvalue $vpn_status
            }
        }
        else{
        $vpn_name = $result
        }
        $counter++
    }

$prtg += "
</prtg>"


$prtg