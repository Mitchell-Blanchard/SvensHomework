workflow Test-WinRM {
    param($NetworkComputers)
    foreach -Parallel -ThrottleLimit 28 ($Computer in $NetworkComputers.IPAddress) {

            if (Test-WSMan -ErrorAction SilentlyContinue -ComputerName $Computer) {
                echo "$Computer"
        }
    }
}

$WinRMEnabled = Test-WinRM -NetworkComputers $(Get-NetNeighbor -AddressFamily IPv4)

$SelectedComputers =$WinRMEnabled | Out-GridView -PassThru -Title "IP Addresses"







#RAM
$RAM = Write-Host "$(((Get-CimInstance -Class Win32_PhysicalMemory -ComputerName .).Capacity | measure-object -Sum).Sum/1GB)GB"

#HDD - Turn Size into GB
(Get-CimInstance -Class Win32_DiskDrive -ComputerName .) | select Caption, Size | Where -property Size -NE $null

#CPU - Get Name