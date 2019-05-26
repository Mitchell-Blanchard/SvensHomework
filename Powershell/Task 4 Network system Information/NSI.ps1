#Get-NetIPAddress -IPAddress 
#Test-WSMan -ComputerName 192.168.43.23
#$?

$min = 0
$max = 255

$FirstOct =  (10,172,192)

Test-Connection -count 1 -ComputerName


for each $ip in $IPAddresses















#Internal Networks
# 10.0.0.0 - 10.255.255.255
# 172.16.0.0 - 172.31.255.255
# 192.168.0.0 - 192.168.255.255