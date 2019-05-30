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
    }
}

$SelectedComputers = $ComputerInfo | Out-GridView -PassThru

foreach ($computer in $SelectedComputers) {
    $Hostname = $Computer.ComputerName
    #$session = New-PSSession -ComputerName "gameplay10" -Credential administrator
    Invoke-Command -Credential "$Hostname" -computerName $hostname -ScriptBlock {Get-Host}
}




#make session and use that one session to get all the info needed
#this means only 1 connection per computer needs to be made