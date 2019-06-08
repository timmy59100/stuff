$password = "asdf" | ConvertTo-SecureString -asPlainText -Force
$username = "root" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
$session = New-SSHSession -ComputerName 192.168.0.1 -KeyFile "C:\Users\Adrian\Desktop\sophosprivate.key" -Credential $credential
$ssh = Invoke-SSHCommand -Index 0 -Command "/usr/local/bin/confd-client.plx get_ipsec_status|grep 'REF_\|all_established'"


$counter = 0
foreach($string in $ssh.output)
    {
        if ($string -contains "0") {
            $result = 0
        }
        elseif ($string -contains "1") {
            $result = 1
        }
        else {
            $result = $string.replace("'REF_IpsS", '')
        }
        if($counter % 2) {
        $vpn_status = $result
        $prtg+= $vpn_name + $vpn_status
        #prtg.add_channel(channel_name=vpn_name, unit="VPN Status", value=vpn_status)
        }
        else{
        $vpn_name = $result
        }
        $counter++
    }

Write-Host $prtg