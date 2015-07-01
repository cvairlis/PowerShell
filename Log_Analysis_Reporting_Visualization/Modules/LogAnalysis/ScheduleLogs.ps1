<# ScheduleLogs script runs every ten minutes to ensure that the database is updated with new events #>
Import-Module LogAnalysis

$array = New-Object System.Collections.ArrayList

<# SYSTEM #>

#here it takes information (logname, eventrecordid, timecreated) of the last record stored in events table of database 
# and stores these information in a string array
[string[]]$lastSystemEvent = Get-LastStoredEvent -LogName System

# it takes index (record id) of last system event stored in database
[int]$lastSystemEventRecordId= $lastSystemEvent.get(1)

# it takes last 50 system events and stores it to eventlogrecord array
[System.Diagnostics.Eventing.Reader.EventLogRecord[]]$SysEvents = Get-WinEvent -LogName System -MaxEvents 500

# this foreach 
foreach ($ev in $SysEvents){
    if($ev.RecordId -ne $lastSystemEventRecordId){
        $a= $array.Add($ev)
    } else {
        break
    }
}



<# APPLICATION #>

#here it takes information (logname, eventrecordid, timecreated) of the last record stored in events table of database 
# and stores these information in a string array
[string[]]$lastApplicationEvent = Get-LastStoredEvent -LogName Application


# it takes index (or record id) of last system event stored in database
[int]$lastApplicationEventRecordId= $lastApplicationEvent.get(1)


# it takes last 50 application events and stores it to eventlogrecord array
[System.Diagnostics.Eventing.Reader.EventLogRecord[]]$ApEvents = Get-WinEvent -LogName Application -MaxEvents 500

# this foreach 
foreach ($ev in $ApEvents){
    if($ev.RecordId -ne $lastApplicationEventRecordId){
        $a = $array.Add($ev)
    } else {
        break
    }
}


<# SECURITY #>


#here it takes information (logname, eventrecordid, timecreated) of the last record stored in events table of database 
# and stores these information in a string array
[string[]]$lastSecurityEvent = Get-LastStoredEvent -LogName Security


# it takes index (or record id) of last system event stored in database
[int]$lastSecurityEventRecordId= $lastSecurityEvent.get(1)

# it takes last 50 security events and stores it to eventlogrecord array
[System.Diagnostics.Eventing.Reader.EventLogRecord[]]$SecEvents = Get-WinEvent -LogName Security -MaxEvents 500

# this foreach 
foreach ($ev in $SecEvents){
    if($ev.RecordId -ne $lastSecurityEventRecordId){
        $a= $array.Add($ev)
    } else {
        break
    }
}


# finally it has been created an array with eventrecord (we can see this piping the array to gm)
# we sort this array by TimeCreated property and we send all new events to database
$array | Sort-Object -Property timecreated | Set-LogEventInDatabase
