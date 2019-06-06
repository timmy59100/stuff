import paramiko


ssh = paramiko.SSHClient()

ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

ssh.connect('192.168.0.1', username='root', key_filename='C:/Users/Adrian/Desktop/sophosprivate.key')

stdin, stdout, stderr = ssh.exec_command("/usr/local/bin/confd-client.plx get_ipsec_status|grep 'REF_\|all_established'")
output = stdout.readlines()
#print(stdout.readlines())
print(stderr.readlines())
ssh.close()

#print(output)
#outputnew = output.replace('R', '')
#print(outputnew)
print(output)
print(type(output))

for string in output:
    string.replace('R', '')
    print(string)
