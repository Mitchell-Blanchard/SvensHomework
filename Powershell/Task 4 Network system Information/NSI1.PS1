Stop-Job *
Remove-Job *

$WinRMEnabledComputers = @()
$NetworkComputers = Get-NetNeighbor -AddressFamily IPv4

foreach ($Computer in $NetworkComputers.IPAddress) {
    start-job -ScriptBlock {Param($Computer)

    Test-WSMan -ErrorAction SilentlyContinue -ComputerName $Computer

    $WinRMEnabled = $?
    $Results = @{}
    $Results.Add("$Computer","$WinRMEnabled")
    $Results

    } -ArgumentList "$Computer"
}

$BackgroundJobs = Get-Job

while ($BackgroundJobs.command -like "Param*") {

    $BackgroundJobs = get-job

    if ($BackgroundJobs.state -contains "Completed") {
        
        $CompletedJob = get-job -state Completed
        $JobResults = Receive-Job -keep -id $CompletedJob.Id

        if ($JobResults.Values -like "*False*") {

            $WinRMEnabledComputers += $JobResults.Keys
            
        }
        Remove-Job -Id $CompletedJob.Id
        
    }
}

$WinRMEnabledComputers