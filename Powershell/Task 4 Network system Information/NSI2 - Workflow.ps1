workflow Test-WinRM {
    param($NetworkComputers)
    foreach -Parallel -ThrottleLimit 28 ($Computer in $NetworkComputers.IPAddress) {

            if (Test-WSMan -ErrorAction SilentlyContinue -ComputerName $Computer) {
                echo "$Computer"
        }
    }
}

$WinRMEnabledIPs = Test-WinRM -NetworkComputers $(Get-NetNeighbor -AddressFamily IPv4)

#Create hashtable for 

foreach ($IP in $WinRMEnabledIPs) {
    $ComputerName = (Resolve-DnsName $IP).NameHost
    $ComputerRAM = Write-Host "$(((Get-CimInstance -Class Win32_PhysicalMemory -ComputerName .).Capacity | measure-object -Sum).Sum/1GB)GB"
    $ComputerHDD = (Get-CimInstance -Class Win32_DiskDrive -ComputerName .) | select Caption, Size | Where -property Size -NE $null

    Set-Variable -Name "$HashTable($ComputerName)" -Value @{}
    $(get-variable -Name "$HashTable($ComputerName)").add("ComputerName", "$ComputerName")
    #$HashTable`_$ComputerName.Add("IPAddress", "$IP")
    #$HashTable`_$ComputerName.Add("RAM", "$ComputerRAM")
    #Get-Variable HashTable_${ComputerName}.Add("HDD", "$ComputerHDD")
}

#RAM
#$RAM = Write-Host "$(((Get-CimInstance -Class Win32_PhysicalMemory -ComputerName .).Capacity | measure-object -Sum).Sum/1GB)GB"

#HDD - Turn Size into GB
#(Get-CimInstance -Class Win32_DiskDrive -ComputerName .) | select Caption, Size | Where -property Size -NE $null

#CPU - Get Name