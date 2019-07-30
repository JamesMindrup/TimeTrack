. G:\Repos\PoshBits\GUIFilePicker.ps1

$VerbosePreference = "Continue"
$TaskLogFile = Get-FileName -initialDirectory "$([Environment]::GetFolderPath('MyDocuments'))\TimeTrack"
$Totals = @()
$TaskLogItems = Import-Csv -Path $TaskLogFile
$prevTimeStamp = $null
foreach ($TaskLogItem in $TaskLogItems) {
    Write-Verbose "$($TaskLogItem.TimeStamp) $($TaskLogItem.Activity) $($TaskLogItem.Taskname) ::: $($prevTimeStamp)"
    if ($prevTimeStamp) {
        $MatchFound = $false
        foreach ($total in $Totals) {
            if ($total.TaskName -eq $currentTask) {
                $total.Minutes = $total.Minutes + (NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)
                $MatchFound = $true
                Write-Verbose "Added $((NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)) minutes to $($total.TaskName)"
                break
            }
        }
        if (!($MatchFound)) {
            $TempObj = New-Object System.Object
            $TempObj | Add-Member -type NoteProperty -Name TaskName -Value $currentTask
            $TempObj | Add-Member -type NoteProperty -Name Minutes -Value (NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)
            $TempObj | Add-Member -type NoteProperty -Name Hours -Value ""
            $Totals += $TempObj
            Write-Verbose "created $($TempObj.TaskName) with $((NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)) minutes"
            Remove-Variable TempObj
        }
    }
    $prevTimeStamp = $TaskLogItem.TimeStamp
    $currentTask = $TaskLogItem.TaskName
    write-verbose "Current task changed to $($CurrentTask)"
}

foreach ($total in $totals) {
    $total.Hours = ($total.Minutes.Hours + [math]::Round(($total.Minutes.Minutes/60),2))
}
$Totals | Out-GridView