function show-menu ($TaskList,$highlight = "Green",$VerbosePreference = "SilentlyContinue") {
    Clear-Host
    Write-Verbose "show-menu: entered"
    Write-Host "Select a task to start"
    Write-Host "(* = Active)"
    Write-Host "======================="
    $i = 1
    foreach ($task in $TaskList) {
        $task.currentindex = $i
        if ($task.active -eq "True") {
            Write-Host "$($i)." -NoNewline
            Write-Host "*" -ForegroundColor $highlight -NoNewline
            Write-Host "$($task.Name)"
        }
        else {Write-Host "$($i). $($task.Name)"}
        $i++
    }
    Write-Host "$($i). NEW Task"
}

function ManageListFile ($FileName, $TaskList, $VerbosePreference = "Continue") {
    Write-Verbose "ManageListFile: entered"
    if ($null -eq $TaskList) {
        if (!(test-path $FileName)) {
            $TempObj = New-Object System.Object
            $TempObj | Add-Member -type NoteProperty -Name Name -Value "Admin"
            $TempObj | Add-Member -type NoteProperty -Name Active -Value "True"
            $TempObj | Add-Member -type NoteProperty -Name CurrentIndex -Value 0
            $TempObj | Export-Csv -NoTypeInformation -Path $FileName -Force
            $Activity = "START"
            ManageLogFile -FileName $TaskLogFile -Activity $Activity -TaskName $TempObj.name
            Remove-Variable TempObj,Activity
            $TempObj = New-Object System.Object
            $TempObj | Add-Member -type NoteProperty -Name Name -Value "End"
            $TempObj | Add-Member -type NoteProperty -Name Active -Value "False"
            $TempObj | Add-Member -type NoteProperty -Name CurrentIndex -Value 0
            $TempObj | Export-Csv -NoTypeInformation -Path $FileName -Append
            Remove-Variable TempObj
        }
        $TaskList = Import-Csv -Path $TaskListFile
    }
    else {
        $TaskList | Export-Csv -NoTypeInformation -Path $FileName -Force
    }

    #remove old list files
    $FilePathFull = $FileName.split("\")
    for ($loop=0;$loop -lt $FilePathFull.GetUpperBound(0);$loop++) {
        if ($loop -eq 0) {$FilePathRoot = $FilePathFull[$loop]}
        else {$FilePathRoot = $FilePathRoot + "\" + $FilePathFull[$loop]}
    }
    Get-ChildItem $FilePathRoot | where-object {($_.name -match 'TaskList-\d{8}\.txt') -and ($_.name -ne $FilePathFull[$FilePathFull.GetUpperBound(0)])} | ForEach-Object {Remove-item $_.FullName}
    
    #return the list
    Return $TaskList
}

function ManageLogFile ($FileName, $Activity, $TaskName, $VerbosePreference = "SilentlyContinue") {
    Write-Verbose "ManageLogFile: entered"
    # !! need to verify path
    $TempObj = New-Object System.Object
    $TempObj | Add-Member -type NoteProperty -Name TimeStamp -Value (Get-Date).ToString()
    $TempObj | Add-Member -type NoteProperty -Name Activity -Value $Activity
    $TempObj | Add-Member -type NoteProperty -Name TaskName -Value $TaskName
    $TempObj | Export-Csv -NoTypeInformation -Path $FileName -Append
    Remove-Variable TempObj
}

# ************* Script Body ********************
$VerbosePreference = "SilentlyContinue"
$TaskListFile = "$([Environment]::GetFolderPath('MyDocuments'))\TimeTrack\TaskList-$((Get-Date).ToString("MMddyyyy")).txt"
$TaskLogFile = "$([Environment]::GetFolderPath('MyDocuments'))\TimeTrack\TaskLog-$((Get-Date).ToString("MMddyyyy")).txt"
$TaskList = ManageListFile -FileName $TaskListFile

do {
    show-menu -TaskList $TaskList -highlight "Cyan"
    $selection = Read-Host "Selection"
    if ($selection.Length -gt 0) {
        if ($TaskList.CurrentIndex -eq "$($Selection)") {
            foreach ($task in $TaskList) {
                if ($Task.CurrentIndex -eq "$($Selection)") {
                    if ($Task.Name -eq "End") {$XiT = $true}
                    $Task.Active = "True"
                    $Activity = "START"
                    ManageLogFile -FileName $TaskLogFile -Activity $Activity -TaskName $task.name
                    Remove-Variable Activity
                }
                else {$Task.Active = "False"}
            }
            $TaskList = ManageListFile -FileName $TaskListFile -TaskList $TaskList
        }
        else {
            foreach ($task in $TaskList) {$Task.Active = "False"}
            if ($selection -match '^\d+$') {$NewTaskName = Read-Host "Enter the task name"}
            else {$NewTaskName = $selection}
            $TempObj = New-Object System.Object
            $TempObj | Add-Member -type NoteProperty -Name Name -Value $NewTaskName
            $TempObj | Add-Member -type NoteProperty -Name Active -Value "True"
            $TempObj | Add-Member -type NoteProperty -Name CurrentIndex -Value 0
            $TaskList += $TempObj
            $Activity = "START"
            ManageLogFile -FileName $TaskLogFile -Activity $Activity -TaskName $TempObj.name
            Remove-Variable TempObj,Activity

            $TaskList = ManageListFile -FileName $TaskListFile -TaskList $TaskList
        }
    }
    else {
        Write-Host "you didn't enter anything...leaving it where it was"
        Start-Sleep -Seconds 5
    }
} While (!($XiT))

# Present a summary
$Totals = @()
$grandTotal = 0
$TaskLogItems = Import-Csv -Path $TaskLogFile
$prevTimeStamp = $null
foreach ($TaskLogItem in $TaskLogItems) {
    Write-Verbose "$($TaskLogItem.TimeStamp) $($TaskLogItem.Activity) $($TaskLogItem.Taskname) ::: $($currentTask) $($prevTimeStamp)"
    if ($currentTask -ne "End") {
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
    }
    else {write-verbose "skipped processing for END"}
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