$ComputerInfo = @()

workflow Test-WinRM {
    param($NetworkComputers)
    foreach -Parallel -ThrottleLimit 28 ($Computer in $NetworkComputers.IPAddress) {

            if (Test-WSMan -ErrorAction SilentlyContinue -ComputerName $Computer) {
                echo "$Computer"
        }
    }
}

$WinRMEnabledIPs = Test-WinRM -NetworkComputers $(Get-NetNeighbor -AddressFamily IPv4)

foreach ($IP in $WinRMEnabledIPs) {
    $ComputerName = (Resolve-DnsName $IP).NameHost

    $ComputerInfo += New-Object -TypeName PSObject -Property @{
        "ComputerName" = "$ComputerName"
        "IPAddress" = "$IP"
        "RAM" = ""
        "CPU" = ""
        "HDDs" = ""
    }
}

$SelectedComputers = ($ComputerInfo.ComputerName) | Out-GridView -PassThru

function ComputerConnections {

    foreach ($computer in $SelectedComputers) {
        set-variable -name "session$computer" -value (New-PSSession -ComputerName $computer -Credential administrator) -Scope script
    }

    foreach ($computer in $SelectedComputers) {
        $RAM = Invoke-Command -Session (get-variable -Name "session$computer").value -ScriptBlock {"$(((Get-CimInstance -Class Win32_PhysicalMemory -ComputerName $ComputerName).Capacity | measure-object -Sum).Sum/1GB)GB"}
        $CPU = Invoke-Command -Session (get-variable -Name "session$computer").value -ScriptBlock {wmic cpu get name}
        
        $Drives = Invoke-Command -Session (get-variable -Name "session$computer").value -ScriptBlock {Get-CimInstance -Class Win32_DiskDrive | Where -property Size -NE $null}
        $Drives = $Drives.Size | ForEach-Object {$_ /1GB}

        $ComputerInfo | Where "ComputerName" -eq $computer | %{$_.RAM=$RAM}
        $ComputerInfo | Where "ComputerName" -eq $computer | %{$_.CPU=$CPU.Name}
        $ComputerInfo | Where "ComputerName" -eq $computer | %{$_.HDDs=$Drives}
    }

}