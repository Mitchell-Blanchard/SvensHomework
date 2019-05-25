stop-job *
remove-job *

$ScriptTime = [system.diagnostics.stopwatch]::StartNew()

start-job -name "sleep1" -ScriptBlock {sleep 1}
start-job -name "sleep10" -ScriptBlock {sleep 10}
start-job -name "sleep300" -ScriptBlock {sleep 300}

$task = Get-Job | where-object {$_.name -like "sleep*"}

while ($task.command -like "sleep*") {

    $task = get-job | where-object {$_.name -like "sleep*"}

    if ($task.state -contains "Completed") {
        
        $completedtask = get-job -state Completed

        $end = $completedtask | Select-Object -ExpandProperty PSEndTime
        $begin = $completedtask | Select-Object -ExpandProperty PSBeginTime
        $time = $end - $begin
        
        echo ""$completedtask.name
        
        if ($timetaken.TotalSeconds -lt 299) {
            write-host $time.TotalSeconds "Seconds"
        }
        else {
            write-host $time.TotalMinutes "Minutes"
        }

        remove-job $completedtask.name
    }
}

$ScriptTime.Stop()
write-host `n"Everything has finished in $($ScriptTime.Elapsed.TotalMinutes) Minutes."
