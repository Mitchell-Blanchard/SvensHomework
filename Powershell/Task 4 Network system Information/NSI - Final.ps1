function main {
    $Credentials = Get-Credential -Message "Enter Credentials you want to be passed to the machines, Network or Local"

    $ComputerInfo = @()

    $buttons = @()
    $buttons += New-Object -TypeName PSObject -Property @{
            "ComputerName" = $null
            "IPAddress" = $null
            "RAM" = "Invoke command on selected remote computers"
            "CPU" = $null
            "HDDs" = $null
            "Results" = $null
    }
    $buttons += New-Object -TypeName PSObject -Property @{
            "ComputerName" = $null
            "IPAddress" = $null
            "RAM" = "Reselect Computers"
            "CPU" = $null
            "HDDs" = $null
            "Results" = $null
    }
    $buttons += New-Object -TypeName PSObject -Property @{
            "ComputerName" = $null
            "IPAddress" = $null
            "RAM" = "Exit"
            "CPU" = $null
            "HDDs" = $null
            "Results" = $null
    }

    $UserRequest = @()
    $UserRequest += New-Object -TypeName PSObject -Property @{
            "ComputerName" = $null
            "IPAddress" = $null
            "RAM" = "Reselect Computers"
            "CPU" = $null
            "HDDs" = $null
            "Results" = $null
    }


    #Function that tests if remote machines have WinRM enabled
    cls
    write-host "Testing WinRm availability on remote machines..."
    workflow Test-WinRM { param($NetworkComputers)
        foreach -Parallel -ThrottleLimit 28 ($Computer in $NetworkComputers.IPAddress) {
                if (Test-WSMan -ErrorAction SilentlyContinue -ComputerName $Computer) {
                    echo "$Computer"
            }
        }
    }

    #stores all ips that have winrm enabled in variable
    $WinRMEnabledIPs = Test-WinRM -NetworkComputers $(Get-NetNeighbor -AddressFamily IPv4)

    #gets the hostname of all the machines IP addresses
    foreach ($IP in $WinRMEnabledIPs) {
        $ComputerName = (Resolve-DnsName $IP).NameHost

        $ComputerInfo += New-Object -TypeName PSObject -Property @{
            "ComputerName" = "$ComputerName"
            "IPAddress" = "$IP"
            "RAM" = $null
            "CPU" = $null
            "HDDs" = $null
            "Results" = $null
        }
    }

    #Opens connections to computers if one isnt already open and updates $ComputerInfo with the machines Specs if they havent already been updated
    function ComputerConnections {

        $FinalComputers = @()

        $SelectedComputers = $ComputerInfo | Out-GridView -Title "Get computer specs" -PassThru

        cls
        write-host "Opening connections to computers."
        foreach ($computer in $SelectedComputers) {
            $ComputerName = $computer.ComputerName
            if ((get-variable -Name "session$ComputerName") -eq $null) {
                set-variable -name "session$ComputerName" -value (New-PSSession -ComputerName $ComputerName -Credential $Credentials) -Scope script
            }
        }

        foreach ($computer in $SelectedComputers) {

            $ComputerName = $computer.ComputerName
            if ($computer.RAM -eq $null) {
                $RAM = Invoke-Command -Session (get-variable -Name "session$ComputerName").value -ScriptBlock {"$(((Get-CimInstance -Class Win32_PhysicalMemory -ComputerName $ComputerName).Capacity | measure-object -Sum).Sum/1GB)GB"}
                $ComputerInfo | Where "ComputerName" -eq $ComputerName | %{$_.RAM=$RAM}
            }

            if ($computer.CPU -eq $null) {
                $CPU = Invoke-Command -Session (get-variable -Name "session$ComputerName").value -ScriptBlock {wmic cpu get name}
                $ComputerInfo | Where "ComputerName" -eq $ComputerName | %{$_.CPU=$CPU[2]}
            }

            if ($computer.Drives -eq $null) {
                $Drives = Invoke-Command -Session (get-variable -Name "session$ComputerName").value -ScriptBlock {Get-CimInstance -Class Win32_DiskDrive | Where -property Size -NE $null}
                $Drives = $Drives.Size | ForEach-Object {$_/1GB}
                $ComputerInfo | Where "ComputerName" -eq $ComputerName | %{$_.HDDs=$Drives}
            }

        }

        return $SelectedComputers

    }

    function SendCommands {

        $SelectedComputers = ComputerConnections

        $FinalComputers = @()

        foreach ($name in ($SelectedComputers.ComputerName)) {
            $FinalComputers += $ComputerInfo | where ComputerName -EQ $name
        }

        $UserRequest = $FinalComputers + $buttons | Out-GridView -Title "Computer Specifications" -PassThru

        If ($UserRequest.Ram -eq "Invoke command on selected remote computers") {

            cls
            write-host "Please enter your command, enter a blank line to submit your command."
            $command = (@(While($l=(Read-Host).Trim()){$l}) -join("`n"))

            foreach ($machine in $FinalComputers) {
                $computer = $machine.ComputerName
                cls
                write-host "Running command on: $computer"
                $Results = Invoke-Command -Session (get-variable -Name "session$computer").Value -scriptblock {invoke-expression $args[0]} -ArgumentList $command
                $ComputerInfo | Where "ComputerName" -eq $computer | %{$_.Results=$Results}
            }

            $FinalComputers = @()
            foreach ($name in ($SelectedComputers.ComputerName)) {
                $FinalComputers += $ComputerInfo | where ComputerName -EQ $name
            }
            $UserRequest = $FinalComputers + $buttons[1,2] | Out-GridView -Title "Command Results" -PassThru
            echo $UserRequest
        }
        return $UserRequest
    }

    while ($UserRequest.RAM -eq "Reselect Computers" -or $UserRequest.RAM -eq "Invoke command on selected remote computers") {
        $UserRequest = Sendcommands
    }
}

main