function show-menu ($TaskList,$VerbosePreference = "SilentlyContinue") {
    Clear-Host
    Write-Verbose "show-menu: entered"
    Write-Host "Select a task to start (this stops the currently active one)"
    Write-Host "============================================================"
    $i = 1
    foreach ($task in $TaskList) {
        $task.currentindex = $i
        if ($task.active -eq "True") {
            Write-Host "$($i). $($task.Name)" -NoNewline
            Write-Host " (active)" -ForegroundColor Green
        }
        else {Write-Host "$($i). $($task.Name)"}
        $i++
    }
    Write-Host "$($i). NEW Task"
}

function ManageListFile ($FileName, $TaskList, $VerbosePreference = "SilentlyContinue") {
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
    
    Return $TaskList
}

function ManageLogFile ($FileName, $Activity, $TaskName, $VerbosePreference = "SilentlyContinue") {
    Write-Verbose "ManageLogFile: entered"
    $TempObj = New-Object System.Object
    $TempObj | Add-Member -type NoteProperty -Name TimeStamp -Value (Get-Date).ToString()
    $TempObj | Add-Member -type NoteProperty -Name Activity -Value $Activity
    $TempObj | Add-Member -type NoteProperty -Name TaskName -Value $TaskName
    $TempObj | Export-Csv -NoTypeInformation -Path $FileName -Append
    Remove-Variable TempObj
}

# ************* Script Body ********************
$VerbosePreference = "Continue"
$TaskListFile = "$([Environment]::GetFolderPath('MyDocuments'))\TaskList-$((Get-Date).ToString("MMddyyyy")).txt"
$TaskLogFile = "$([Environment]::GetFolderPath('MyDocuments'))\TaskLog-$((Get-Date).ToString("MMddyyyy")).txt"
$TaskList = ManageListFile -FileName $TaskListFile

do {
    show-menu -TaskList $TaskList
    $selection = Read-Host "Selection"

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
        $NewTaskName = Read-Host "Enter the task name"
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

} While (!($XiT))