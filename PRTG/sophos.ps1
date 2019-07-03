
$password = "asdf" | ConvertTo-SecureString -asPlainText -Force
$username = "root"
$keyfile = "C:\Users\Administrator\Desktop\sophosprivate.key"
$command = "/usr/local/bin/confd-client.plx get_ipsec_status|grep 'REF_\|all_established'"


$credential = New-Object System.Management.Automation.PSCredential($username,$password)
$session = New-SSHSession -ComputerName 192.168.246.1 -KeyFile $keyfile -Credential $credential
$ssh = Invoke-SSHCommand -Index 0 -Command $command


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
        $prtg += add-Channel -channelname $vpn_name -channelvalue $vpn_status
        }
        else{
        $vpn_name = $result
        }
        $counter++
    }

$prtg += "
</prtg>"
Remove-Item "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\data.txt"

$prtg >> "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\data.txt"