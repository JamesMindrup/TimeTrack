. G:\Repos\PoshBits\GUIFilePicker.ps1

$VerbosePreference = "Continue"
$TaskLogFile = Get-FileName -initialDirectory "$([Environment]::GetFolderPath('MyDocuments'))\TimeTrack"
$Totals = @()
$grandTotal = 0
$TaskLogItems = Import-Csv -Path $TaskLogFile
$prevTimeStamp = $null
foreach ($TaskLogItem in $TaskLogItems) {
    Write-Verbose "$($TaskLogItem.TimeStamp) $($TaskLogItem.Activity) $($TaskLogItem.Taskname) ::: $($prevTimeStamp)"
    if ($prevTimeStamp) {
        $MatchFound = $false
        foreach ($total in $Totals) {
            if ($total.TaskName -eq $currentTask) {
                $addMinutes = (NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)
                $total.Minutes = $total.Minutes + $addMinutes
                $grandTotal = $grandTotal + $addMinutes
                $MatchFound = $true
                Write-Verbose "Added $((NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)) minutes to $($total.TaskName)"
                Remove-Variable addMinutes
                break
            }
        }
        if (!($MatchFound)) {
            $addMinutes = (NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)
            $grandTotal = $grandTotal + $addMinutes
            $TempObj = New-Object System.Object
            $TempObj | Add-Member -type NoteProperty -Name TaskName -Value $currentTask
            $TempObj | Add-Member -type NoteProperty -Name Minutes -Value $addMinutes
            $TempObj | Add-Member -type NoteProperty -Name Hours -Value ""
            $Totals += $TempObj
            Write-Verbose "created $($TempObj.TaskName) with $((NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)) minutes"
            Remove-Variable TempObj,addMinutes
        }
    }
    $prevTimeStamp = $TaskLogItem.TimeStamp
    $currentTask = $TaskLogItem.TaskName
    write-verbose "Current task changed to $($CurrentTask)"
}
$TempObj = New-Object System.Object
$TempObj | Add-Member -type NoteProperty -Name TaskName -Value "GrandTotal"
$TempObj | Add-Member -type NoteProperty -Name Minutes -Value $grandTotal
$TempObj | Add-Member -type NoteProperty -Name Hours -Value ""
$Totals += $TempObj
Write-Verbose "created $($TempObj.TaskName) with $((NEW-TIMESPAN -Start $prevTimeStamp -End $TaskLogItem.TimeStamp)) minutes"
Remove-Variable TempObj

foreach ($total in $totals) {
    $total.Hours = ($total.Minutes.Hours + [math]::Round(($total.Minutes.Minutes/60),2))
}
$Totals | Out-GridView -Title "Results from '$($TaskLogFile)'" -Wait