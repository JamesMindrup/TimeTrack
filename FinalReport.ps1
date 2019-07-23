#$TaskLogFile = "$([Environment]::GetFolderPath('MyDocuments'))\TaskLog-$((Get-Date).ToString("MMddyyyy")).txt"
$TaskLogFile = "$([Environment]::GetFolderPath('MyDocuments'))\TaskLog-07222019.txt"
$Totals = @()
$TaskLogItems = Import-Csv -Path $TaskLogFile
$prevTimeStamp = $null
foreach ($TaskLogItem in $TaskLogItems) {
    Write-Verbose "$($TaskLogItem.TimeStamp) $($TaskLogItem.Activity) $($TaskLogItem.Taskname) ::: $($prevTimeStamp)"
    if ($prevTimeStamp) {
        $MatchFound = $false
        foreach ($total in $Totals) {
            if ($total.TaskName -eq $TaskLogItem.TaskName) {
                $total.Minutes = $total.Minutes + (NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)
                $MatchFound = $true
                Write-Verbose "Added $((NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)) minutes to $($total.TaskName)"
                break
            }
        }
        if (!($MatchFound)) {
            $TempObj = New-Object System.Object
            $TempObj | Add-Member -type NoteProperty -Name TaskName -Value $TaskLogItem.TaskName
            $TempObj | Add-Member -type NoteProperty -Name Minutes -Value (NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)
            $TempObj | Add-Member -type NoteProperty -Name Hours -Value ""
            $Totals += $TempObj
            Remove-Variable TempObj
            Write-Verbose "created $($total.TaskName) with $((NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)) minutes"
        }
    }
    $prevTimeStamp = $TaskLogItem.TimeStamp
}

foreach ($total in $totals) {
    $total.Hours = ($total.Minutes.Hours + [math]::Round(($total.Minutes.Minutes/60),2))
}
$Totals | Out-GridView