$LogErrorLogPreference = 'c:\log-retries.txt'
$LogConnectionString = 
        "server=localhost\SQLEXPRESS;database=LogDB;trusted_connection=True"

# Imports LogDatabase Module in order to be able to use Get-LogDatabaseData and Invoke-LogDatabaseQuery cmdlets.
Import-Module LogDatabase


<#
  # ______________________________________________________________________________________________________ 
  # ======================================================================================================

  LogAnalysis Module contains 18 cmdlets. All these "LogAnalysis" cmdlets are divided in two 3 major groups.
  

   ## First Group ##
    # cmdlets that are used only within this module
      Get-DatabaseAvailableTableNames
      Set-LogEventInDatabase
      Set-TableAutoIncrementValue
      Clear-TableContentsFromDatabase
      Get-LogonType
      Get-ImpersonationLevelExplanation
      Get-StatusExplanation
      Get-DatesUntilNow
      Get-TimeRangesForNames
      Get-TimeRangesForValues


   ## Second Group ##
    # cmdlets that are used only from the script: "LogVisualization.ps1"      
      Get-TableRowNumber
      Get-LastEventDateFromDatabase
      Get-EventsOccured
      Get-HashTableForPieChart
      Get-HashTableForTimeLineChart
      Get-LogonIpAddresses
      Get-TableContents


   ## Third Group ##
    # cmdlets that are used only from the script: "ScheduleLogs.ps1"
      Get-LastStoredEvent


   # ======================================================================================================
   # ______________________________________________________________________________________________________

#>


# ==================================================================
## First Group ## START
# cmdlets that are used only within this module

<#
.NAME
   Get-DatabaseAvailableTableNames

.SYNOPSIS
   Gets the available table names from database.

.SYNTAX
   Get-DatabaseAvailableTableNames
   
.DESCRIPTION
   The Get-DatabaseAvailableTableNames cmdlet gets the available table names from database.
   More specifically it will go out, send a query to the database and outputs a dataset that 
   will contains values of type strings representing the names of the tables of the database.
   
   The Get-DatabaseAvailableTableNames is been used from the Set-LogEventInDatabase cmdlet.
   
.PARAMETERS
   None

.INPUTS
   None

.OUTPUTS
   [System.Data.DataSet]

.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-DatabaseAvailableTableNames

   This will return a dataset if strings that represent the names of the available tables of the database.

#>
function Get-DatabaseAvailableTableNames
{
    [CmdletBinding()]
    Param()
    Process
    {
        Get-LogDatabaseData -connectionString $LogConnectionString `
                            -isSQLServer `
                            -query "SELECT TABLE_NAME
                                    FROM INFORMATION_SCHEMA.TABLES
                                    WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG='LogDB'"                       
    }
}


<#
.NAME
   Set-LogEventInDatabase

.SYNOPSIS
   Sets the events in database.

.SYNTAX
   Set-LogEventInDatabase [[-EventLogRecordObject <System.Diagnostics.Eventing.Reader.EventLogRecord[]>]]

.DESCRIPTION
   The Set-LogEventInDatabase cmdlet is basically the first cmdlet it has been written for the LogAnalysis Module. 
   It accepts objects of type: System.Diagnostics.Eventing.Reader.EventLogRecord and it works for storing 
   information of events to the Database.

   Basically Set-LogEventInDatabase is going to grab all of the events came from the pipeline and insert them into the database. 
   For each event that comes from the pipeline Set-LogEventInDatabase takes all of its properties and inserts them into the EVENTS table, one event at a row.
   
   If a Security Event comes from the pipeline Set-LogEventInDatabase is able to create new tables 
   (for events with Id 4624, 4625, 4907, 4672, 4634, 4648, 4797, 4776, 4735) if they do not exist.   

.PARAMETERS
   -EventLogRecordObject <System.Diagnostics.Eventing.Reader.EventLogRecord[]>
    Gives to the cmdlet an array of objects to be set in database.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   [System.Diagnostics.Eventing.Reader.EventLogRecord]

   You can pipe EventLogRecord objects as input to this cmdlet.

.OUTPUTS
   None

.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-WinEvent -LogName Application, Security, System | Sort-Object -Property TimeCreated | Set-LogEventInDatabase

   This command uses the Get-WinEvent cmdlet to get all of the Application, Security and System events. It uses a pipeline operator (|) 
   to send events to the Sort-Object cmdlet. Sort-Obejct command sort all these events by property TimeCreated and it uses pipeline again 
   to send events to the Set-LogEventInDatabase command. Set-LogEventInDatabase cmdlet accepts all these eventlogrecord objects 
   and sends the objects, one at a time, to be parsed and stored in the Database.
   
.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------
  

   PS C:\> Get-WinEvent -LogName Application, Security, System | Sort-Object -Property TimeCreated | Where-Object -FilterScript {($_.Timecreated).Year -eq 2015} | Set-LogEventInDatabase

   This command uses the Get-WinEvent cmdlet to get all of the Application, Security and System events. It uses a pipeline operator (|) 
   to send events to the Sort-Object cmdlet. Sort-Obejct command sort all these events by property TimeCreated and it uses pipeline again 
   to send events to the Where-Object cmdlet. Where-Object is going to filter only events that created in year 2015 and send the to the 
   Set-LogEventInDatabase command. Set-LogEventInDatabase cmdlet accepts all these eventlogrecord objects and sends the objects, one at a time,
   to be parsed and stored in the Database.

#>
function Set-LogEventInDatabase
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]$EventLogRecordObject       
    )
    Process
    {
        <# if you pass an eventlogrecord array as a parameter in Set-LogEventInDatabase cmdlet
           foreach loop will take this array and run the procedure foreach object of this array
           ---
           on the other hand if you pass eventlogrecord objects from the pipeline 
           Set-LogEventInDatabase cmdlet will accept these objects one by one
           and foreach loop will be not used
        #>
        foreach ($ev in $EventLogObject){        
            Write-Verbose "It will be stored $events.Count events from $log eventlog in database."
            
            # there was a problem by inserting in database nvarchar that contains "'" and ";" characters
            # for this reason we replace char(') and char(;) with blank character to eliminate problems 
            [String]$messagestr = (($ev.Message -replace "'","") -replace ";","")
            # here the query is been made               
            $query = "INSERT INTO EVENTS VALUES
                ('$($ev.Id)',
                 '$($ev.Version)',
                 '$($ev.Level)',
                 '$($ev.Task)',
                 '$($ev.Opcode)',
                 '$($ev.Keywords)',
                 '$($ev.RecordId)',
                 '$($ev.ProviderName)',
                 '$($ev.ProviderId)',
                 '$($ev.LogName)',
                 '$($ev.ProcessId)',
                 '$($ev.ThreadId)',
                 '$($ev.MachineName)',
                 '$($ev.TimeCreated)',
                 '$($ev.LevelDisplayName)',
                 '$($ev.OpcodeDisplayName)',
                 '$($ev.TaskDisplayName)',
                 '$($ev.KeywordsDisplayNames)',
                 '$messagestr')"
                 
            Write-Verbose "Query will be: '$query'"
            # here the query is been invoked
            Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                    -isSQLServer `
                                    -query $query
            
            <# After inserting basic events information in the database,
             # Set-LogEventInDatabase will parse the message string of some critical security events
             # and will create substantive tables with many critical information.
             # 
             # Critical events that tranform into tables are:
             #  - DETAILS4624 : Successfull Logons
             #  - DETAILS4625 : Failure Logons
             #  - DETAILS4907 : Auditing settings on object were changed.
             #  - DETAILS4672 : Special privileges assigned to new logon.
             #  - DETAILS4634 : An account was logged off.
             #  - DETAILS4648 : A logon was attempted using explicit credentials.
             #  - DETAILS4797 : An attempt was made to query the existence of a blank password for an account.
             #  - DETAILS4776 : The computer attempted to validate the credentials for an account.
             #  - DETAILS4735 : A security-enabled local group was changed.
             #>
            if ($ev.LogName -eq "Security") {            
                $evMessage = $ev.Message.ToString()
                [String[]]$splitMessage = $evMessage -split "\r\n"
                $shortMessage = $splitMessage.Get(0)                
                if ($ev.Id -eq 4624){                    
                    [String]$tableName = "DETAILS4624"                         
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) PRIMARY KEY NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,
                                                        [LogonType] [nvarchar](max) NULL,
                                                        [ImpersonationLevel] [nvarchar](max) NULL,
                                                        [ImpersonationLevelExplanation] [nvarchar](max) NULL,
                                                        [NewLogonSID] [nvarchar](max) NULL,
                                                        [NewLogonAccount] [nvarchar](max) NULL,
                                                        [CallerProccessId] [nvarchar](max) NULL,
                                                        [CallerProcessName] [nvarchar](max) NULL,
                                                        [SourceWorkStationName] [nvarchar](max) NULL,
                                                        [SourceNetworkAddress] [nvarchar](max) NULL,
                                                        [SourcePort] [nvarchar](max) NULL,
                                                        [LogonProcess] [nvarchar](max) NULL,
                                                        [AuthenticationPackage] [nvarchar](max) NULL,                                                            
                                                         )"
                    }

                    $sid = $splitMessage.get(3).split(":").get(1).trimstart().trimend()

                    [String]$temp1 = $splitMessage.get(4).split(":").get(1).trimstart().trimend()
                    [String]$temp2 = $splitMessage.get(5).split(":").get(1).trimstart().trimend()
                    [String]$sidCaption = $temp2 + "\" + $temp1

                    [int]$logtype = $splitMessage.get(8).split(":").get(1).trimstart().trimend()
                    $logontype = Get-LogonType -LogonType $logtype
                    
                    $impLevel =  $splitMessage.get(10).split(":").get(1).trimstart().trimend()
                    $impLevelExplanation = Get-ImpersonationLevelExplanation -ImpersonationLevel $impLevel

                    $newLogonSid = $splitMessage.get(13).split(":").get(1).trimstart().trimend()

                    [string]$tempAcc1 = $splitMessage.get(14).split(":").get(1).trimstart().trimend()
                    [string]$tempAcc2 = $splitMessage.get(15).split(":").get(1).trimstart().trimend()

                    [string]$newLogonAcc = $tempAcc2 + "\" +$tempAcc1                  

                    [string]$callerProcessId = $splitMessage.get(20).split(":").get(1).trimstart().trimend().ToString()
                    
                    [string[]]$callerProcessNameTemp1 = $splitMessage.get(21).split("")
                    [int]$callerProcessNameTemp2 = $callerProcessNameTemp1.count-1
                    $callerProcessName = $splitMessage.get(21).split("").get($callerProcessNameTemp2)
                    
                    [string]$sourceWorkstationName = $splitMessage.get(24).split(":").get(1).trimstart().trimend()
                    [String]$sourceNetworkAddress = $splitMessage.get(25).split(":").get(1).trimstart().trimend()
                    [string]$sourcePort = $splitMessage.get(26).split(":").get(1).trimstart().trimend()

                    [string]$logonProcess = $splitMessage.get(29).split(":").get(1).trimstart().trimend()
                    [string]$authenticationPackage = $splitMessage.get(30).split(":").get(1).trimstart().trimend()

                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption',
                            '$logontype',
                            '$impLevel',
                            '$impLevelExplanation',
                            '$newLogonSid',
                            '$newLogonAcc', 
                            '$callerProcessId',
                            '$callerProcessName',
                            '$sourceWorkstationName', 
                            '$sourceNetworkAddress',
                            '$sourcePort',
                            '$logonProcess',
                            '$authenticationPackage')"      
                
                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: '$query'"
    
                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query                                         
                } elseif ($ev.Id -eq 4625) {
                   [String]$tableName = "DETAILS4625"
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE DETAILS4625 (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,
                                                        [LogonType] [nvarchar](max) NULL,                                                        
                                                        [NewLogonSID] [nvarchar](max) NULL,
                                                        [NewLogonAccount] [nvarchar](max) NULL,
                                                        [FailureReason] [nvarchar](max) NULL,
                                                        [Status] [nvarchar](max) NULL,
                                                        [SubStatus] [nvarchar](max) NULL,                                                       
                                                        [CallerProccessId] [nvarchar](max) NULL,
                                                        [CallerProcessName] [nvarchar](max) NULL,
                                                        [SourceWorkStationName] [nvarchar](max) NULL,
                                                        [SourceNetworkAddress] [nvarchar](max) NULL,
                                                        [SourcePort] [nvarchar](max) NULL,
                                                        [LogonProcess] [nvarchar](max) NULL,
                                                        [AuthenticationPackage] [nvarchar](max) NULL, 
                                                        CONSTRAINT PK_DETAILS4625 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                                        
                    $sid = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)

                    [String]$temp1 = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)
                    [String]$temp2 = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").Count-1)
                    [String]$sidCaption = $temp2 + "\" + $temp1

                    [int]$logtype = $splitMessage.get(8).split("").get($splitMessage.get(8).split("").Count-1)
                    $logontype = Get-LogonType -LogonType $logtype
                  
                    $newLogonSid = $splitMessage.get(11).split("").get($splitMessage.get(11).split("").Count-1)

                    [string]$tempAcc1 = $splitMessage.get(12).split("").get($splitMessage.get(12).split("").Count-1)
                    [string]$tempAcc2 = $splitMessage.get(13).split("").get($splitMessage.get(13).split("").Count-1)

                    [string]$newLogonAcc = $tempAcc2 + "\" +$tempAcc1
                    #[string]$logonId = $splitMessage.get(16).split(":").get(1).trimstart().trimend()

                    [String]$failureReason = $splitMessage.Get(16).Split(":").Get(1).TrimStart().TrimEnd()

                    [string]$statusCode = $splitMessage.Get(17).Split("").Get($splitMessage.get(17).split("").count-1)
                    [string]$status = Get-StatusExplanation -Status $statusCode
                    [string]$subCode = $splitMessage.Get(18).Split("").Get($splitMessage.get(18).split("").count-1) 
                    [string]$subStatus = Get-StatusExplanation -Status $subCode

                    [string]$callerProcessId = $splitMessage.get(21).split("").Get($splitMessage.get(21).split("").count-1)
                                        
                    [string[]]$callerProcessNameTemp1 = $splitMessage.get(22).split("")
                   
                    [String]$callerProcessName = $splitMessage.get(22).split("").Get($splitMessage.get(22).split("").count-1)
                  
                    [string]$sourceWrkStName = $splitMessage.Get(25).Split("").Get($splitMessage.Get(25).Split("").Count-1)
                    [string]$sourceNtwAd = $splitMessage.Get(26).Split("").Get($splitMessage.Get(26).Split("").Count-1)
                    [string]$sourcePrt = $splitMessage.Get(27).Split("").Get($splitMessage.Get(27).Split("").Count-1)

                    [string]$logonProcess = $splitMessage.get(30).split(":").Get(1).TrimStart().TrimEnd()
                    [string]$authenticationPackage = $splitMessage.get(31).split("").Get($splitMessage.Get(31).Split("").Count-1)

                    $query = "INSERT INTO DETAILS4625 VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption',
                            '$logontype',
                            '$newLogonSid',
                            '$newLogonAcc',
                            '$failureReason',
                            '$status',
                            '$subStatus',
                            '$callerProcessId',
                            '$callerProcessName',
                            '$sourceWrkStName', 
                            '$sourceNtwAd',
                            '$sourcePrt',
                            '$logonProcess',
                            '$authenticationPackage')"  
                
                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: '$query'"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query
                } elseif ($ev.Id -eq 4907) {
                    [String]$tableName = "DETAILS4907"                        
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,
                                                        [CallerProcessId] [nvarchar](max) NULL,
                                                        [CallerProcessName] [nvarchar](max) NULL,
                                                        [ObjectServer] [nvarchar](max) NULL,
                                                        [ObjectType] [nvarchar](max) NULL,
                                                        [ObjectName] [nvarchar](max) NULL,
                                                        [HandleId] [nvarchar](max) NULL,                                                        
                                                        [OriginalSecurityDescriptor] [nvarchar](max) NULL,
                                                        [NewSecurityDescriptor] [nvarchar](max) NULL,                                                        
                                                        CONSTRAINT PK_DETAILS4907 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                                         
                    $sid = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)

                    [String]$temp1 = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)
                    [String]$temp2 = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").Count-1)
                    [String]$sidCaption = $temp2 + "\" + $temp1

                    [string]$objectServer = $splitMessage.get(9).split("").get($splitMessage.get(9).split("").Count-1)
                    [string]$objectType = $splitMessage.get(10).split("").get($splitMessage.get(10).split("").Count-1)

                    [string]$objectName = $splitMessage.get(11).split("").get($splitMessage.get(11).split("").Count-1)
                    [string]$handleId = $splitMessage.get(12).split("").get($splitMessage.get(12).split("").Count-1)
                  
                    [string]$callerProcessId = $splitMessage.get(15).split(":").Get(1).TrimStart().TrimEnd()
                    
                    [String]$callerProcessNameTemp = $splitMessage.Get(16) -split ("Process Name:")                 
                                      
                    [String]$callerProcessName = $callerProcessNameTemp.TrimStart()
                   
                  
                    [string]$originalSecurityDescriptor = $splitMessage.Get(19).Split("").get($splitMessage.Get(19).split("").Count-1)
                    [string]$newSecurityDescriptor = $splitMessage.Get(20).Split("").get($splitMessage.Get(20).split("").Count-1)
                    
                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption',
                            '$callerProcessId',
                            '$callerProcessName',
                            '$objectServer',
                            '$objectType',
                            '$objectName',
                            '$handleId',
                            '$originalSecurityDescriptor',
                            '$newSecurityDescriptor')"

                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: $query"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query                         
                } elseif ($ev.Id -eq 4672) {
                    [String]$tableName = "DETAILS4672"                        
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,                                                                                                             
                                                        CONSTRAINT PK_DETAILS4672 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                                         
                    $sid = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)

                    [String]$temp1 = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)
                    [String]$temp2 = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").Count-1)
                    [String]$sidCaption = $temp2 + "\" + $temp1
                               

                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption')"

                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: $query"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query
                } elseif ($ev.Id -eq 4634) {
                    [String]$tableName = "DETAILS4634"                        
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,   
                                                        [LogonType] [nvarchar](max) NULL,                                                                                                            
                                                        CONSTRAINT PK_DETAILS4634 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                                         
                    $sid = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)

                    [String]$temp1 = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)
                    [String]$temp2 = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").Count-1)
                    [String]$sidCaption = $temp2 + "\" + $temp1

                    [int]$logtype = $splitMessage.get(8).split("").get($splitMessage.get(8).split("").Count-1)
                    $logontype = Get-LogonType -LogonType $logtype
                    
                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption',
                            '$logontype')"

                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: $query"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query
                } elseif ($ev.Id -eq 4648) {
                    [String]$tableName = "DETAILS4648"                        
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,   
                                                        [LogonAttempAccount] [nvarchar](max) NULL,   
                                                        [TargetServerName] [nvarchar](max) NULL,  
                                                        [TargetServerInfo] [nvarchar](max) NULL,  
                                                        [ProcessId] [nvarchar](max) NULL, 
                                                        [ProcessName] [nvarchar](max) NULL, 
                                                        [NetworkAddress] [nvarchar](max) NULL, 
                                                        [NetworkPort] [nvarchar](max) NULL, 
                                                        CONSTRAINT PK_DETAILS4648 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                                         
                    $sid = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)

                    [String]$temp1 = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)
                    [String]$temp2 = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").Count-1)
                    [String]$sidCaption = $temp2 + "\" + $temp1

                    [String]$tempAc1 = $splitMessage.get(10).split("").get($splitMessage.get(10).split("").count-1)
                    [String]$tempAc2 = $splitMessage.get(11).split("").get($splitMessage.get(11).split("").Count-1)
                    [String]$logonAttempAccount = $tempAc2 + "\" + $tempAc1

                    [String]$targetServerName = $splitMessage.get(15).split("").get($splitMessage.get(15).split("").Count-1)

                    [String]$targetServerInfo = $splitMessage.get(16).split("").get($splitMessage.get(16).split("").Count-1)
                    
                    [String]$processId = $splitMessage.get(19).split("").get($splitMessage.get(19).split("").Count-1)

                    [String]$processName = $splitMessage.get(20).split("").get($splitMessage.get(20).split("").Count-1)
                    
                    [String]$networkAddress = $splitMessage.get(23).split("").get($splitMessage.get(23).split("").Count-1)

                    [String]$networkPort = $splitMessage.get(24).split("").get($splitMessage.get(24).split("").Count-1)
                    
                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption',
                            '$logonAttempAccount',
                            '$targetServerName',
                            '$targetServerInfo',
                            '$processId',
                            '$processName',
                            '$networkAddress',
                            '$networkPort')"

                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: $query"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query
                }  elseif ($ev.Id -eq 4797) {
                    [String]$tableName = "DETAILS4797"                        
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,   
                                                        [CallerWorkStation] [nvarchar](max) NULL,   
                                                        [TargetAccount] [nvarchar](max) NULL,  
                                                        CONSTRAINT PK_DETAILS4797 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                                         
                    $sid = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)

                    $callerWorkstation = $splitMessage.get(9).split("").get($splitMessage.get(9).split("").count-1)

                    [String]$temp1 = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)
                    [String]$temp2 = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").Count-1)
                    [String]$sidCaption = $temp2 + "\" + $temp1

                    [String]$tempAc1 = $splitMessage.get(10).split("").get($splitMessage.get(10).split("").count-1)
                    [String]$tempAc2 = $splitMessage.get(11).split("").get($splitMessage.get(11).split("").Count-1)
                    [String]$targetAccount = $tempAc2 + "\" + $tempAc1

                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption',
                            '$callerWorkstation',
                            '$targetAccount')"

                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: $query"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query
                } elseif ($ev.Id -eq 4776) {
                    [String]$tableName = "DETAILS4776"                        
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [AuthenticationPackage] [nvarchar](max) NULL,
                                                        [LogonAccount] [nvarchar](max) NULL,   
                                                        [SourceWorkstation] [nvarchar](max) NULL,   
                                                        [ErrorCode] [nvarchar](max) NULL,  
                                                        CONSTRAINT PK_DETAILS4776 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                   
                    [string]$authenticationPackage = $splitMessage.get(2).split("").get($splitMessage.get(2).split("").count-1)
                    [string]$logonAccount = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)
                    [string]$sourceWorkstation = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)                    
                    [string]$errorCode = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").count-1)
                    
                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$authenticationPackage',
                            '$logonAccount',
                            '$sourceWorkstation',
                            '$errorCode')"

                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: $query"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query
                }  elseif ($ev.Id -eq 4735) {
                    [String]$tableName = "DETAILS4735"                        
                    if (!((Get-DatabaseAvailableTableNames).table_name).contains($tableName)){                        
                        Write-Verbose "Table $tableName not found. It will be created."                        
                        Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                                -isSQLServer `
                                                -query "CREATE TABLE $tableName (
                                                        [Id] [bigint] IDENTITY(1,1) NOT NULL,
                                                        [LogName] [nvarchar](50) NULL,
                                                      	[EventId] [int] NULL,
	                                                    [EventRecordId] [int] NULL,
                                                        [LevelDisplayName] [nvarchar](max) NULL,
	                                                    [Message] [nvarchar](max) NULL,
                                                    	[TimeCreated] [nvarchar](max) NULL,
                                                        [ComputerName] [nvarchar](max) NULL,
	                                                    [SID] [nvarchar](max) NULL,
                                                        [SIDCaption] [nvarchar](max) NULL,   
                                                        [GroupSID] [nvarchar](max) NULL,   
                                                        [GroupCaption] [nvarchar](max) NULL, 
                                                        [ChangedAccountName] [nvarchar](max) NULL,
                                                        [ChangesHistory] [nvarchar](max) NULL, 
                                                        CONSTRAINT PK_DETAILS4735 PRIMARY KEY CLUSTERED (Id ASC) 
                                                        ON [PRIMARY]                                                           
                                                         )"
                    }
                   
                    [string]$sid = $splitMessage.get(3).split("").get($splitMessage.get(3).split("").count-1)

                    [String]$temp1 = $splitMessage.get(4).split("").get($splitMessage.get(4).split("").count-1)
                    [String]$temp2 = $splitMessage.get(5).split("").get($splitMessage.get(5).split("").Count-1)
                    [String]$sidCaption = $temp2 + "\" + $temp1  
                                      
                    [string]$groupSid = $splitMessage.get(9).split("").get($splitMessage.get(9).split("").count-1)

                    [String]$tempGr1 = $splitMessage.get(10).split("").get($splitMessage.get(10).split("").count-1)
                    [String]$tempGr2 = $splitMessage.get(11).split("").get($splitMessage.get(11).split("").Count-1)
                    [String]$groupCaption = $tempGr2 + "\" + $tempGr1

                    [string]$changedAccountName = $splitMessage.get(14).split("").get($splitMessage.get(14).split("").count-1)
                    [string]$changesHistory = $splitMessage.get(15).split("").get($splitMessage.get(15).split("").count-1)
                                        
                    $query = "INSERT INTO $tableName VALUES
                           ('$($ev.LogName)',
                            '$($ev.Id)',
                            '$($ev.RecordId)',
                            '$($ev.LevelDisplayName)',
                            '$shortMessage',
                            '$($ev.TimeCreated)',
                            '$($ev.MachineName)',
                            '$sid',
                            '$sidCaption',
                            '$groupSid',
                            '$groupCaption',
                            '$changedAccountName',
                            '$changesHistory')"

                    Write-Verbose "oh found security event $($ev.LogName)"
                    Write-Verbose "Query will be: $query"

                    Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                            -isSQLServer `
                                            -query $query
                } 
            }
        }       
    }
}


<#
.NAME
   Set-TableAutoIncrementValue

.SYNOPSIS
   Sets the auto increment value of a table to be zero.

.SYNTAX
   Set-TableAutoIncrementValue
   
.DESCRIPTION
   All the tables in database created to automatically generate a unique number when a new record is inserted into a table.
   Set-TableAutoIncrementValue cmdlet is used from Clear-TableContentsFromDatabase cmdlet.
   
.PARAMETERS
   -Table <String[]>
    Gives to the cmdlet a string value that represents a table name.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   None

.NOTES

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Set-TableAutoIncrementValue -Table EVENTS

.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> Set-TableAutoIncrementValue -Table EVENTS, DETAILS4624
   
#>
function Set-TableAutoIncrementValue
{
    [CmdletBinding()]    
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table 
    )
    Begin
    {
        $Value=0
    }
    Process
    {
        foreach ($ta in $Table){
                $query = "DBCC CHECKIDENT ('$ta',reseed,$Value)"               
                Write-Verbose "Query from 'Set-TableAutoIncrementValue cmdlet' will be: '$query'"
                Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                        -isSQLServer `
                                        -query $query
        }        
    }
}


<#
.NAME
   Clear-TableContentsFromDatabase

.SYNOPSIS
   It removes all the contents from any table of the database.

.SYNTAX
   
.DESCRIPTION   
   This cmdlet Clear-TableContentsFromDatabase helps you interact with the LogDatabase
   and erase the contents of a specific table. You can pass multible tables at once. See examples.

.PARAMETERS
   -Table <String[]>
    Gives to the cmdlet a string value that represents a table name.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   None

.NOTES

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Clear-TableContentsFromDatabase -Table EVENTS

.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> Clear-TableContentsFromDatabase -Table EVENTS, DETAILS4624
   
#>
function Clear-TableContentsFromDatabase
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table
    )
    Process
    {
        foreach ($ta in $Table) {
            $query = "DELETE FROM $ta"
            Write-Verbose "Query will be '$query'"
            Write-Verbose "Deleted Records FOR '$ta' Table:"
            Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                    -isSQLServer `
                                    -query $query

            Set-TableAutoIncrementValue -Table: $ta         
        }
    }
}


<#
.NAME
   Get-LogonType

.SYNOPSIS
   Gets the explanation of a logon type.

.SYNTAX
   Get-LogonType [[-LogonType] <Int32>]
   
.DESCRIPTION
   For some security events there is a logon type within the message of the event.
   This logon type is represented by a number. This cmdlet takes as a parameter 
   the Logon Type as an integer and returns a string with what this integer means.
   
.PARAMETERS
   -LogonType <Int32>
    Gives to the cmdlet an integer value that represents a logon type.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

   You cannot pipe input to this cmdlet.

.OUTPUTS
   [System.String]
   
.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-LogonType -LogonType 8

#>
function Get-LogonType
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]$LogonType
    )
    Process
    {
        switch ($LogonType){
            2{"2: Interactive (logon at keyboard and screen of system)";break}
            3{"3: Network (i.e. connection to shared folder on this computer from elsewhere on network)";break}
            4{"4: Batch (i.e. scheduled task)";break}
            5{"5: Service (Service startup)";break}
            7{"7: Unlock (i.e. unnattended workstation with password protected screen saver)";break}
            8{"8: NetworkCleartext (Logon with credentials sent in the clear text. Most often indicates a logon to IIS with basic authentication)";break}
            9{"9: NewCredentials such as with RunAs or mapping a network drive with alternate credentials.  This logon type does not seem to show up in any events.";break}
            10{"10: RemoteInteractive (Terminal Services, Remote Desktop or Remote Assistance)";break}
            11{"11: CachedInteractive (logon with cached domain credentials such as when logging on to a laptop when away from the network)";break}
            default {"Logon Type could not be determined."}
        }
    }
}


<#
.NAME
   Get-ImpersonationLevelExplanation

.SYNOPSIS
   Gets the explanation of an impersonation level.

.SYNTAX
   Get-ImpersonationLevelExplanation [[-ImpersonationLevel] <String>]
   
.DESCRIPTION
   For security events with id 4624 there is an impersonation level within the message of the event.
   This impersonation level is represented by a string. This cmdlet takes as a parameter 
   the impersonation level as a string and returns a string with what this impersonation level means.
   
.PARAMETERS
   -ImpersonationLevel <String>
    Gives to the cmdlet a string value that represents an impersonation level.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None
   
   You cannot pipe input to this cmdlet.

.OUTPUTS
   [System.String]

.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-ImpersonationLevelExplanation -ImpersonationLevel Anonymous

#>
function Get-ImpersonationLevelExplanation
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]$ImpersonationLevel
    )
    Process
    {
        switch ($ImpersonationLevel) {
            "Anonymous"{"Anonymous COM impersonation level that hides the identity of the caller. Calls to WMI may fail with this impersonation level.";break}
            "Default"{"Default impersonation.";break}
            "Delegate"{"Delegate-level COM impersonation level that allows objects to permit other objects to use the credentials of the caller. This level, which will work with WMI calls but may constitute an unnecessary security risk, is supported only under Windows 2000."; break}
            "Identify"{"Identify-level COM impersonation level that allows objects to query the credentials of the caller. Calls to WMI may fail with this impersonation level."; break}
            "Impersonation"{"Impersonate-level COM impersonation level that allows objects to use the credentials of the caller. This is the recommended impersonation level for WMI calls."; break}
             default {"Impersonation Level could not be determined."}
        }
    }
}


<#
.NAME
   Get-StatusExplanation

.SYNOPSIS
   Gets the explanation of an event status.

.SYNTAX
   Get-StatusExplanation [[-Status] <String>]
   
.DESCRIPTION
   For security events with id 4625 there is an status within the message of the event.
   This status is represented by a hexadecimal number. This cmdlet takes as a parameter 
   the status as a string and returns a string with what this status means.
   
.PARAMETERS
   -Status <String>
    Gives to the cmdlet a string value that represents an event status.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

   You cannot pipe input to this cmdlet.

.OUTPUTS
   [System.String]

.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-StatusExplanation -Status 0xC0000064

#>
function Get-StatusExplanation
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Status
    )
    Process
    {
        switch ($Status){
            "0xC0000064"{"User name does not exist.";break}
            "0xC000006A"{"User name is correct but the password is wrong.";break}
            "0xC0000234"{"User is currently locked out.";break}
            "0xC0000072"{"Account is currently disabled.";break}
            "0xC000006F"{"User tried to logon outside his day of week or time of day restrictions.";break}
            "0xC0000070"{"Workstation restriction.";break}
            "0xC0000193"{"Account expiration.";break}
            "0xC0000071"{"Expired password.";break}
            "0xC0000133"{"Clocks between DC and other computer too far out of sync.";break}
            "0xC0000224"{"User is required to change password at next logon.";break}
            "0xC0000225"{"Evidently a bug in Windows and not a risk.";break}
            "0xc000015b"{"The user has not been granted the requested logon type (aka logon right) at this machine.";break}
            default{$Status}
        }        
    }
}


<#
.NAME
   Get-DatesUntilNow

.SYNOPSIS
   Gets an array of datetime object from a specified date until now.

.SYNTAX
   Get-DatesUntilNow [-DateTime <DateTime>] [-Reverse <switch>]
   
.DESCRIPTION
   This cmdlet is been created in order to work with Get-TimeRangesForNames and Get-TimeRangesForValues.
      
.PARAMETERS
   -DateTime <DateTime>
    Gives to the cmdlet a datetime value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -Reverse <switch>
    Determines if the array will be reversed or not.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

   You cannot pipe input to this cmdlet.

.OUTPUTS
   [System.Collections.ArrayList] 
    with DateTime objects

.NOTES

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-DatesUntilNow -DateTime (Get-Date).AddDays(-20)
      
   This example will output the following:

   Tuesday, June 30, 2015 4:50:22 PM
   Monday, June 29, 2015 4:50:22 PM
   Sunday, June 28, 2015 4:50:22 PM
   Saturday, June 27, 2015 4:50:22 PM
   Friday, June 26, 2015 4:50:22 PM
   Thursday, June 25, 2015 4:50:22 PM
   Wednesday, June 24, 2015 4:50:22 PM
   Tuesday, June 23, 2015 4:50:22 PM
   Monday, June 22, 2015 4:50:22 PM
   Sunday, June 21, 2015 4:50:22 PM
   Saturday, June 20, 2015 4:50:22 PM
   Friday, June 19, 2015 4:50:22 PM
   Thursday, June 18, 2015 4:50:22 PM
   Wednesday, June 17, 2015 4:50:22 PM
   Tuesday, June 16, 2015 4:50:22 PM
   Monday, June 15, 2015 4:50:22 PM
   Sunday, June 14, 2015 4:50:22 PM
   Saturday, June 13, 2015 4:50:22 PM
   Friday, June 12, 2015 4:50:22 PM
   Thursday, June 11, 2015 4:50:22 PM
   Wednesday, June 10, 2015 4:50:22 PM

.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> [System.DateTime]$date = "06/01/2015"
   PS C:\> Get-DatesUntilNow -DateTime $date -Reverse

   This example will output the following:

   Monday, June 1, 2015 4:48:43 PM
   Tuesday, June 2, 2015 4:48:43 PM
   Wednesday, June 3, 2015 4:48:43 PM
   Thursday, June 4, 2015 4:48:43 PM
   Friday, June 5, 2015 4:48:43 PM
   Saturday, June 6, 2015 4:48:43 PM
   Sunday, June 7, 2015 4:48:43 PM
   Monday, June 8, 2015 4:48:43 PM
   Tuesday, June 9, 2015 4:48:43 PM
   Wednesday, June 10, 2015 4:48:43 PM
   Thursday, June 11, 2015 4:48:43 PM
   Friday, June 12, 2015 4:48:43 PM
   Saturday, June 13, 2015 4:48:43 PM
   Sunday, June 14, 2015 4:48:43 PM
   Monday, June 15, 2015 4:48:43 PM
   Tuesday, June 16, 2015 4:48:43 PM
   Wednesday, June 17, 2015 4:48:43 PM
   Thursday, June 18, 2015 4:48:43 PM
   Friday, June 19, 2015 4:48:43 PM
   Saturday, June 20, 2015 4:48:43 PM
   Sunday, June 21, 2015 4:48:43 PM
   Monday, June 22, 2015 4:48:43 PM
   Tuesday, June 23, 2015 4:48:43 PM
   Wednesday, June 24, 2015 4:48:43 PM
   Thursday, June 25, 2015 4:48:43 PM
   Friday, June 26, 2015 4:48:43 PM
   Saturday, June 27, 2015 4:48:43 PM
   Sunday, June 28, 2015 4:48:43 PM
   Monday, June 29, 2015 4:48:43 PM
   Tuesday, June 30, 2015 4:48:43  

#>
function Get-DatesUntilNow
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.DateTime]$DateTime,
        [switch]$Reverse
    )
    Begin
    {
        $DatesArray = New-Object System.Collections.ArrayList
        $co = 0
    }
    Process
    {   
        $timeSpan = (New-TimeSpan -Start (Get-Date) -End $DateTime).Days*-1

        for ($in =0; $in -le $timeSpan; $in++ ) {
            $forDay = (Get-Date).AddDays(-$in)
            $ArrayListAddition = $DatesArray.Add($forDay)
            $co = $co-1
        }    
        
        if ($Reverse){
            $DatesArray.Reverse()
        }         
    }
    End
    {        
        return $DatesArray
    }
}


<#
.NAME
   Get-TimeRangesForNames

.SYNOPSIS
   Gets an array of time ranges until the current date.

.SYNTAX
   Get-TimeRangesForNames [-DateTime <DateTime>]
   
.DESCRIPTION
   This cmdlet is used by the Get-HashTableForTimeLineChart cmdlet.
   Charts in Windows Forms can have as data source a hash table.
   Every record on a hash table basically consists of name and value.
   In order to make time line charts we had to specify names and values.
   With this way Get-TimeRangesForNames will provide the names that our hash table will contain.

   In addition, Get-TimeRangesForNames works as follows:
    - If we want to get time ranges from a date that abstains from the current date less than 7 days:
      time ranges will be hourly separated (see example 1)
    - If we want to get time ranges from a date that abstains from the current date more than 7 days but less than 30 days:
      time ranges will be daily separated (see example 2)
    - If we want to get time ranges from a date that abstains from the current date more than 30 days:
      time ranges will be weekly separated (see example 3)
         
.PARAMETERS
   -DateTime <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false


.INPUTS
   None

.OUTPUTS
   [System.Collections.ArrayList] 
    with string value objects
.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> [System.DateTime]$date = "06/29/2015"
   PS C:\> Get-TimeRangesForNames -DateTime $date

   This example will output the following:

   29_Jun_00-01
   29_Jun_01-02
   29_Jun_02-03
   29_Jun_03-04
   29_Jun_04-05
   29_Jun_05-06
   29_Jun_06-07
   29_Jun_07-08
   29_Jun_08-09
   29_Jun_09-10
   29_Jun_10-11
   29_Jun_11-12
   29_Jun_12-13
   29_Jun_13-14
   29_Jun_14-15
   29_Jun_15-16
   29_Jun_16-17
   29_Jun_17-18
   29_Jun_18-19
   29_Jun_19-20
   29_Jun_20-21
   29_Jun_21-22
   29_Jun_22-23
   29_Jun_23-00
   30_Jun_00-01
   30_Jun_01-02
   30_Jun_02-03
   30_Jun_03-04
   30_Jun_04-05
   30_Jun_05-06
   30_Jun_06-07
   30_Jun_07-08
   30_Jun_08-09
   30_Jun_09-10
   30_Jun_10-11
   30_Jun_11-12
   30_Jun_12-13
   30_Jun_13-14
   30_Jun_14-15
   30_Jun_15-16
   30_Jun_16-17
   30_Jun_17-18
   30_Jun_18-19
   30_Jun_19-20
   30_Jun_20-21
   30_Jun_21-22
   30_Jun_22-23
   30_Jun_23-00

.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> [System.DateTime]$date = "06/01/2015"
   PS C:\> Get-TimeRangesForNames -DateTime $date
   
   This example will output the following:

   01_Jun
   02_Jun
   03_Jun
   04_Jun
   05_Jun
   06_Jun
   07_Jun
   08_Jun
   09_Jun
   10_Jun
   11_Jun
   12_Jun
   13_Jun
   14_Jun
   15_Jun
   16_Jun
   17_Jun
   18_Jun
   19_Jun
   20_Jun
   21_Jun
   22_Jun
   23_Jun
   24_Jun
   25_Jun
   26_Jun
   27_Jun
   28_Jun
   29_Jun
   30_Jun
   
.EXAMPLE

   -------------------------- EXAMPLE 3 --------------------------

   PS C:\> [System.DateTime]$date = "05/01/2015"
   PS C:\> Get-TimeRangesForNames -DateTime $date

   This example will output the following:

   01_May-02_May
   03_May-09_May
   10_May-16_May
   17_May-23_May
   24_May-30_May
   31_May-06_Jun
   07_Jun-13_Jun
   14_Jun-20_Jun
   21_Jun-27_Jun
   28_Jun-04_Jul

#>
function Get-TimeRangesForNames
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$DateTime
    )

     Begin
    {
        $namesArray = New-Object System.Collections.ArrayList
        # converts the string value came from the parameter to a datetime object
        $DateToWorkWith = [System.DateTime]$DateTime
        # by creating a timespan object we can find how many days the datetime that came as input abstains from the current date
        $timeSpan = New-TimeSpan -Start $DateToWorkWith -End (get-date)
    }
    Process
    {
        # if the received date abstains from the current date less that 7 days (number 7)
        # hour time ranges will be constructed
        if ($timeSpan.Days -lt 7){
            # for each day makes ranges of hour
            for ($i = 0 ; ($i -le $timeSpan.Days); $i++){
                for ($j = 0; $j -le 23; $j++){
                    switch ($j){
                    0{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_00-01";break}
                    1{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_01-02";break}
                    2{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_02-03";break}
                    3{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_03-04";break}
                    4{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_04-05";break}
                    5{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_05-06";break}
                    6{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_06-07";break}
                    7{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_07-08";break}
                    8{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_08-09";break}
                    9{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_09-10";break}
                    10{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_10-11";break}
                    11{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_11-12";break}
                    12{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_12-13";break}
                    13{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_13-14";break}
                    14{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_14-15";break}
                    15{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_15-16";break}
                    16{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_16-17";break}
                    17{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_17-18";break}
                    18{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_18-19";break}
                    19{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_19-20";break}
                    20{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_20-21";break}
                    21{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_21-22";break}
                    22{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_22-23";break}
                    23{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_23-00";break}
                    }
                    $addition = $namesArray.Add($temp)
                }
            }
            
        # if the received date abstains from the current date more that 7 but less than 30 days
        # day time ranges will be constructed
        } elseif ($timeSpan.Days -gt 7 -and $timeSpan.Days -le 30){
            for ($i=0; $DateToWorkWith.AddDays($i).date -le (Get-Date).date; $i++){
                $temp = $DateToWorkWith.AddDays($i).ToString("dd_MMM")  
                $addition = $namesArray.Add($temp)
            }
            
        # if the received date abstains from the current date more that 30 days
        # week time ranges will be constructed
        } elseif ($timeSpan.Days -gt 30){                    
            if ($DateToWorkWith.DayOfWeek.value__ -ne 0){
                switch ($DateToWorkWith.DayOfWeek.value__){
                1 { 
                    $temp = $DateToWorkWith.ToString("dd_MMM")+"-"+$DateToWorkWith.AddDays(5).ToString("dd_MMM")
                    $next = $DateToWorkWith.AddDays(6)
                ;break}
                2 { 
                    $temp = $DateToWorkWith.ToString("dd_MMM")+"-"+$DateToWorkWith.AddDays(4).ToString("dd_MMM")
                    $next = $DateToWorkWith.AddDays(5)
                ;break}
                3 { 
                    $temp = $DateToWorkWith.ToString("dd_MMM")+"-"+$DateToWorkWith.AddDays(3).ToString("dd_MMM")
                    $next = $DateToWorkWith.AddDays(4)
                ;break}
                4 { 
                    $temp = $DateToWorkWith.ToString("dd_MMM")+"-"+$DateToWorkWith.AddDays(2).ToString("dd_MMM")
                    $next = $DateToWorkWith.AddDays(3)
                ;break}
                5 { 
                    $temp = $DateToWorkWith.ToString("dd_MMM")+"-"+$DateToWorkWith.AddDays(1).ToString("dd_MMM")
                    $next = $DateToWorkWith.AddDays(2)
                ;break}
                6 { 
                    $temp = $DateToWorkWith.ToString("dd_MMM")+"-"+$DateToWorkWith.AddDays(5).ToString("dd_MMM")
                    $next = $DateToWorkWith.AddDays(1)
                ;break}

                }
                $addition = $namesArray.Add($temp)
            } else {
                $next = $DateToWorkWith
            }
            
            [System.Collections.ArrayList]$dates = (Get-DatesUntilNow -DateTime $next)
            $dates.reverse()
            
            foreach ($date in $dates){

                if ($date.DayOfWeek.value__ -eq 0){
                    $temp = $date.ToString("dd_MMM")+"-"+$date.AddDays(6).ToString("dd_MMM")
                    $addition = $namesArray.Add($temp)
                }                
            }
        }
    }
    End
    {       
        # finally it outputs a System.Collections.ArrayList
        Write-Output $namesArray
    }
    
}


<#
.NAME
   Get-TimeRangesForValues

.SYNOPSIS
   Gets an array of time ranges until the current date to be used as SQL Queries.

.SYNTAX
   Get-TimeRangesForValues [-DateTime <DateTime>]
   
.DESCRIPTION
   This cmdlet is used by the Get-HashTableForTimeLineChart cmdlet.
   Charts in Windows Forms can have as data source a hash table.
   Every record on a hash table basically consists of name and value.
   In order to make time line charts we had to specify names and values.
   With this way Get-TimeRangesForValues will provide the values that our hash table will contain.

   In addition, Get-TimeRangesForValues works as follows:
    - If we want to get time ranges from a date that abstains from the current date less than 7 days:
      time ranges will be hourly separated (see example 1)
    - If we want to get time ranges from a date that abstains from the current date more than 7 days but less than 30 days:
      time ranges will be daily separated (see example 2)
    - If we want to get time ranges from a date that abstains from the current date more than 30 days:
      time ranges will be weekly separated (see example 3)
         
.PARAMETERS
   -DateTime <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false


.INPUTS
   None

.OUTPUTS
   [System.Collections.ArrayList] 
    with string value objects
.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> [System.DateTime]$date = "06/29/2015"
   PS C:\> Get-TimeRangesForValues -DateTime $date

   This example will output the following:

   '06/29/2015 00:00:00' AND '06/29/2015 00:59:59'
   '06/29/2015 01:00:00' AND '06/29/2015 01:59:59'
   '06/29/2015 02:00:00' AND '06/29/2015 02:59:59'
   '06/29/2015 03:00:00' AND '06/29/2015 03:59:59'
   '06/29/2015 04:00:00' AND '06/29/2015 04:59:59'
   '06/29/2015 05:00:00' AND '06/29/2015 05:59:59'
   '06/29/2015 06:00:00' AND '06/29/2015 06:59:59'
   '06/29/2015 07:00:00' AND '06/29/2015 07:59:59'
   '06/29/2015 08:00:00' AND '06/29/2015 08:59:59'
   '06/29/2015 09:00:00' AND '06/29/2015 09:59:59'
   '06/29/2015 10:00:00' AND '06/29/2015 10:59:59'
   '06/29/2015 11:00:00' AND '06/29/2015 11:59:59'
   '06/29/2015 12:00:00' AND '06/29/2015 12:59:59'
   '06/29/2015 13:00:00' AND '06/29/2015 13:59:59'
   '06/29/2015 14:00:00' AND '06/29/2015 14:59:59'
   '06/29/2015 15:00:00' AND '06/29/2015 15:59:59'
   '06/29/2015 16:00:00' AND '06/29/2015 16:59:59'
   '06/29/2015 17:00:00' AND '06/29/2015 17:59:59'
   '06/29/2015 18:00:00' AND '06/29/2015 18:59:59'
   '06/29/2015 19:00:00' AND '06/29/2015 19:59:59'
   '06/29/2015 20:00:00' AND '06/29/2015 20:59:59'
   '06/29/2015 21:00:00' AND '06/29/2015 21:59:59'
   '06/29/2015 22:00:00' AND '06/29/2015 22:59:59'
   '06/29/2015 23:00:00' AND '06/29/2015 23:59:59'
   '06/30/2015 00:00:00' AND '06/30/2015 00:59:59'
   '06/30/2015 01:00:00' AND '06/30/2015 01:59:59'
   '06/30/2015 02:00:00' AND '06/30/2015 02:59:59'
   '06/30/2015 03:00:00' AND '06/30/2015 03:59:59'
   '06/30/2015 04:00:00' AND '06/30/2015 04:59:59'
   '06/30/2015 05:00:00' AND '06/30/2015 05:59:59'
   '06/30/2015 06:00:00' AND '06/30/2015 06:59:59'
   '06/30/2015 07:00:00' AND '06/30/2015 07:59:59'
   '06/30/2015 08:00:00' AND '06/30/2015 08:59:59'
   '06/30/2015 09:00:00' AND '06/30/2015 09:59:59'
   '06/30/2015 10:00:00' AND '06/30/2015 10:59:59'
   '06/30/2015 11:00:00' AND '06/30/2015 11:59:59'
   '06/30/2015 12:00:00' AND '06/30/2015 12:59:59'
   '06/30/2015 13:00:00' AND '06/30/2015 13:59:59'
   '06/30/2015 14:00:00' AND '06/30/2015 14:59:59'
   '06/30/2015 15:00:00' AND '06/30/2015 15:59:59'
   '06/30/2015 16:00:00' AND '06/30/2015 16:59:59'
   '06/30/2015 17:00:00' AND '06/30/2015 17:59:59'
   '06/30/2015 18:00:00' AND '06/30/2015 18:59:59'
   '06/30/2015 19:00:00' AND '06/30/2015 19:59:59'
   '06/30/2015 20:00:00' AND '06/30/2015 20:59:59'
   '06/30/2015 21:00:00' AND '06/30/2015 21:59:59'
   '06/30/2015 22:00:00' AND '06/30/2015 22:59:59'
   '06/30/2015 23:00:00' AND '06/30/2015 23:59:59'

.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> [System.DateTime]$date = "06/01/2015"
   PS C:\> Get-TimeRangesForValues -DateTime $date
   
   This example will output the following:

   '06/01/2015 00:00:00' AND '06/01/2015 23:59:59'
   '06/02/2015 00:00:00' AND '06/02/2015 23:59:59'
   '06/03/2015 00:00:00' AND '06/03/2015 23:59:59'
   '06/04/2015 00:00:00' AND '06/04/2015 23:59:59'
   '06/05/2015 00:00:00' AND '06/05/2015 23:59:59'
   '06/06/2015 00:00:00' AND '06/06/2015 23:59:59'
   '06/07/2015 00:00:00' AND '06/07/2015 23:59:59'
   '06/08/2015 00:00:00' AND '06/08/2015 23:59:59'
   '06/09/2015 00:00:00' AND '06/09/2015 23:59:59'
   '06/10/2015 00:00:00' AND '06/10/2015 23:59:59'
   '06/11/2015 00:00:00' AND '06/11/2015 23:59:59'
   '06/12/2015 00:00:00' AND '06/12/2015 23:59:59'
   '06/13/2015 00:00:00' AND '06/13/2015 23:59:59'
   '06/14/2015 00:00:00' AND '06/14/2015 23:59:59'
   '06/15/2015 00:00:00' AND '06/15/2015 23:59:59'
   '06/16/2015 00:00:00' AND '06/16/2015 23:59:59'
   '06/17/2015 00:00:00' AND '06/17/2015 23:59:59'
   '06/18/2015 00:00:00' AND '06/18/2015 23:59:59'
   '06/19/2015 00:00:00' AND '06/19/2015 23:59:59'
   '06/20/2015 00:00:00' AND '06/20/2015 23:59:59'
   '06/21/2015 00:00:00' AND '06/21/2015 23:59:59'
   '06/22/2015 00:00:00' AND '06/22/2015 23:59:59'
   '06/23/2015 00:00:00' AND '06/23/2015 23:59:59'
   '06/24/2015 00:00:00' AND '06/24/2015 23:59:59'
   '06/25/2015 00:00:00' AND '06/25/2015 23:59:59'
   '06/26/2015 00:00:00' AND '06/26/2015 23:59:59'
   '06/27/2015 00:00:00' AND '06/27/2015 23:59:59'
   '06/28/2015 00:00:00' AND '06/28/2015 23:59:59'
   '06/29/2015 00:00:00' AND '06/29/2015 23:59:59'
   '06/30/2015 00:00:00' AND '06/30/2015 23:59:59'
   
.EXAMPLE

   -------------------------- EXAMPLE 3 --------------------------

   PS C:\> [System.DateTime]$date = "05/01/2015"
   PS C:\> Get-TimeRangesForValues -DateTime $date

   This example will output the following:

   '05/01/2015 00:00:00' AND '05/02/2015 23:59:59'
   '05/03/2015 00:00:00' AND '05/09/2015 23:59:59'
   '05/10/2015 00:00:00' AND '05/16/2015 23:59:59'
   '05/17/2015 00:00:00' AND '05/23/2015 23:59:59'
   '05/24/2015 00:00:00' AND '05/30/2015 23:59:59'
   '05/31/2015 00:00:00' AND '06/06/2015 23:59:59'
   '06/07/2015 00:00:00' AND '06/13/2015 23:59:59'
   '06/14/2015 00:00:00' AND '06/20/2015 23:59:59'
   '06/21/2015 00:00:00' AND '06/27/2015 23:59:59'
   '06/28/2015 00:00:00' AND '07/04/2015 23:59:59'

#>
function Get-TimeRangesForValues
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$DateTime
    )

    Begin
    {
        $datesArray = New-Object System.Collections.ArrayList
        # converts the string value came from the parameter to a datetime object
        $DateToWorkWith = [System.DateTime]$DateTime
        # by creating a timespan object we can find how many days the datetime that came as input abstains from the current date
        $timeSpan = New-TimeSpan -Start $DateToWorkWith -End (get-date)
    }
    Process
    {
        # if the received date abstains from the current date less that 7 days (number 7)
        # hour time ranges will be constructed
        if ($timeSpan.Days -lt 7){
            # for each day makes ranges of hour
            # ready to be used as sql queries
            for ($i = 0 ; ($i -le $timeSpan.Days); $i++){
                for ($j = 0; $j -le 23; $j++){
                    switch ($j){
                    0{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 00:59:59")+"'";break}
                    1{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 01:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 01:59:59")+"'";break}
                    2{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 02:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 02:59:59")+"'";break}
                    3{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 03:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 03:59:59")+"'";break}
                    4{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 04:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 04:59:59")+"'";break}
                    5{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 05:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 05:59:59")+"'";break}
                    6{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 06:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 06:59:59")+"'";break}
                    7{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 07:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 07:59:59")+"'";break}
                    8{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 08:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 08:59:59")+"'";break}
                    9{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 09:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 09:59:59")+"'";break}
                    10{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 10:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 10:59:59")+"'";break}
                    11{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 11:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 11:59:59")+"'";break}
                    12{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 12:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 12:59:59")+"'";break}
                    13{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 13:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 13:59:59")+"'";break}
                    14{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 14:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 14:59:59")+"'";break}
                    15{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 15:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 15:59:59")+"'";break}
                    16{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 16:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 16:59:59")+"'";break}
                    17{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 17:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 17:59:59")+"'";break}
                    18{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 18:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 18:59:59")+"'";break}
                    19{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 19:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 19:59:59")+"'";break}
                    20{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 20:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 20:59:59")+"'";break}
                    21{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 21:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 21:59:59")+"'";break}
                    22{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 22:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 22:59:59")+"'";break}
                    23{ $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 23:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 23:59:59")+"'";break}
                    }
                    $addition = $datesArray.Add($temp)
                }
            }
        # if the received date abstains from the current date more that 7 but less than 30 days
        # day time ranges will be constructed
        # ready to be used as sql queries
        } elseif ($timeSpan.Days -gt 7 -and $timeSpan.Days -le 30){

             for ($i=0; $DateToWorkWith.AddDays($i).date -le (Get-Date).date; $i++){
                $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 23:59:59")+"'"
                $addition = $datesArray.Add($temp)
            } 
        # if the received date abstains from the current date more that 30 days
        # week time ranges will be constructed
        # ready to be used as sql queries
        } elseif ($timeSpan.Days -gt 30){
            if ($DateToWorkWith.DayOfWeek.value__ -ne 0){
                switch ($DateToWorkWith.DayOfWeek.value__){
                1 { 
                    $temp = "'"+$DateToWorkWith.ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays(5).ToString("MM/dd/yyyy 23:59:59")+"'"
                    $next = $DateToWorkWith.AddDays(6)
                ;break}
                2 { 
                    $temp = "'"+$DateToWorkWith.ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays(4).ToString("MM/dd/yyyy 23:59:59")+"'"
                    $next = $DateToWorkWith.AddDays(5)
                ;break}
                3 { 
                    $temp = "'"+$DateToWorkWith.ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays(3).ToString("MM/dd/yyyy 23:59:59")+"'"
                    $next = $DateToWorkWith.AddDays(4)
                ;break}
                4 { 
                    $temp = "'"+$DateToWorkWith.ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays(2).ToString("MM/dd/yyyy 23:59:59")+"'"
                    $next = $DateToWorkWith.AddDays(3)
                ;break}
                5 { 
                    $temp = "'"+$DateToWorkWith.ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays(1).ToString("MM/dd/yyyy 23:59:59")+"'"
                    $next = $DateToWorkWith.AddDays(2)
                ;break}
                6 { 
                    $temp = "'"+$DateToWorkWith.ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.ToString("MM/dd/yyyy 23:59:59")+"'"
                    $next = $DateToWorkWith.AddDays(1)
                ;break}

                }
                $addition = $datesArray.Add($temp)
            } else {
                $next = $DateToWorkWith
            }            
            [System.Collections.ArrayList]$dates = (Get-DatesUntilNow -DateTime $next)
            $dates.reverse()            
            foreach ($date in $dates){
                if ($date.DayOfWeek.value__ -eq 0){
                    $temp = "'"+$date.ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$date.AddDays(6).ToString("MM/dd/yyyy 23:59:59")+"'"
                    $addition = $datesArray.Add($temp)
                }      
            }            
        }        
    }
    End
    {      
        # finally it outputs a System.Collections.ArrayList  
        Write-Output $datesArray
    }
}

## First Group ## END
# cmdlets that are used only within this module
# ==================================================================



# ==================================================================
## Second Group ## START
# cmdlets that are used only from the script: "LogVisualization.ps1"

<#
.NAME
   Get-TableRowNumber

.SYNOPSIS
   Get a number that represents rows of a table in database.

.SYNTAX
   Get-TableRowNumber [-Table <String[]>] [-After <String>]
   
.DESCRIPTION
   This cmdlet is used by the first window of the "LogVisualization.ps1" in order to inform the user 
   about how many event record exist in the database.    
   
.PARAMETERS
   -Table <String[]>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -After <String>
    Gives to the cmdlet a string value.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   An integer value.

.NOTES

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-TableRowNumber -Table Events -After "05/01/2015"
   45049

.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> Get-TableRowNumber -Table Events -After "06/26/2015"
   4641

#>
function Get-TableRowNumber
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table,
        [String]$After
    )
    Process
    {
        foreach ($ta in $Table){
            if ($After -eq 0){                  
                [int]$number = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query "SELECT COUNT(*) from $ta").item(0)

                Write-Output $number
            } else {
                [int]$number = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query "SELECT COUNT(*) AS Count from $ta
                                         WHERE TimeCreated >= '$After'").Count

                Write-Output $number
            }        
        }
    }
}


<#
.NAME
   Get-LastEventDateFromDatabase

.SYNOPSIS
   Gets the date of the last event of the database.

.SYNTAX
   Get-LastEventDateFromDatabase [-Table <String>]
   
.DESCRIPTION
   This cmdlet makes an sql query to receive an String value. 
   This string is the output of the cmdlet and represents the timecreated column value
   of the last record found in the database. In other words it finds the oldest record 
   of a table and returns the timecreated column value.

.PARAMETERS
   -Table <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false 

.INPUTS
  None

.OUTPUTS
  A string value.

.NOTES

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-LastEventDateFromDatabase events
   
   This example will output the following:
   
   01/30/2015 12:49:38

#>
function Get-LastEventDateFromDatabase
{
    [CmdletBinding()]
    #[OutputType([String])]
    Param
    (        
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Table       
    )
    Process
    {
        [string]$eve = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                               -isSQLServer `
                                               -query "SELECT TOP 1 TimeCreated from $Table").TimeCreated
        # Write-Output 
        $eve                                         
    }
}


<#
.NAME
   Get-EventsOccured

.SYNOPSIS
   Get the number of the events that have been occured.

.SYNTAX
   Get-EventsOccured [-Table <String>] [-After <String>] [-LogName <String>] [-SecurityType <String>]
   
.DESCRIPTION
   This cmdlet provides an integer value to be displayed in the EventsOccured TextField of the LogVisualization script. 
   
.PARAMETERS
   -Table <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -After <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

    -LogName <String>
    Gives to the cmdlet a string value.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

    -SecurityType <String>
    Gives to the cmdlet a string value.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   An integer value.

.NOTES

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-EventsOccured -Table Events -After "06/25/2015"

   This example will output the following:

   5718

.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> Get-EventsOccured -Table Events -After "06/25/2015" -LogName Application

   This example will output the following:

   238

.EXAMPLE

   -------------------------- EXAMPLE 3 --------------------------

   PS C:\> Get-EventsOccured -Table Events -After "06/25/2015" -LogName Security -SecurityType Failure

   This example will output the following:

   388

#>
function Get-EventsOccured
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Table,
        [Parameter(Mandatory=$true)]
        [string]$After,
        [string]$LogName,
        [string]$SecurityType
    )
    Process
    {
        if ($LogName.Equals("")){
            $query = "SELECT COUNT(*) AS Count FROM $Table
                      WHERE TimeCreated >= '$After'"
        } elseif ($LogName -ne ""){
            if ($LogName -ne "Security"){
                $query = "SELECT COUNT(*) AS Count FROM $Table
                          WHERE LogName = '$LogName' 
                          AND TimeCreated >= '$After'"
            } elseif ($LogName -eq "Security"){               
                if ($SecurityType -eq "Failure"){
                    $query = "SELECT COUNT(*) AS Count FROM $Table
                              WHERE LogName = '$LogName' AND EventId = 4625
                              AND TimeCreated >= '$After'"

                } elseif ($SecurityType -eq "Success"){
                    $query = "SELECT COUNT(*) AS Count FROM $Table
                              WHERE LogName = '$LogName' AND EventId = 4624
                              AND TimeCreated >= '$After'"

                } elseif ($SecurityType -eq ""){
                    $query = "SELECT COUNT(*) AS Count FROM $Table
                              WHERE LogName = '$LogName' 
                              AND TimeCreated >= '$After'"
                }
            }
        }
    }
    End
    {
        # finally has the query and communicates with the database
        $result = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query $query).Count
        Write-Output $result
    }
}


<#
.NAME
   Get-HashTableForPieChart

.SYNOPSIS
   Gets a hash table to be used for pie chart.

.SYNTAX
   Get-HashTableForPieChart [[-Table <String>] [-After <String>]]

   Get-HashTableForPieChart [[-Table <String>] [-After <String>] [-LogName <String>]]
   
.DESCRIPTION
   This cmdlet is used from the LogVisualization script in order to display the pie charts.
   It implements simple group by queries to retrieve data from database.   
   
.PARAMETERS
   -Table <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -After <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -LogName <String>
    Gives to the cmdlet a string value.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   [System.Collections.Hashtable]

.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-HashTableForPieChart -Table EVENTS -After "06/01/2015"

   This example will output the following:
   
   Name                           Value
   ----                           -----
   Application                    2003
   System                         4646
   Security                       16968


.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> Get-HashTableForPieChart -Table EVENTS -After "06/01/2015" -LogName Security

   This example will output the following:

   Name                           Value
   ----                           -----
   4722                           1
   4648                           1899
   4647                           13
   4776                           2554
   4902                           9
   4728                           1
   4616                           7
   4672                           3085
   4720                           1
   4624                           3124
   4634                           2568
   4907                           165
   1100                           9
   5024                           9
   4717                           1
   4738                           5
   4732                           2
   4723                           1
   4797                           136
   4608                           9
   4625                           3359
   4724                           1
   5033                           9

#>
function Get-HashTableForPieChart
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string]$Table,
        [Parameter(Mandatory=$true)]
        [string]$After,
        [string]$LogName
    )
    Begin
    {
        [System.Collections.Hashtable]$hashTable = [ordered]@{}
    }
    Process
    {
        # if a logname has not been specified information will be grouped by logname
        if ($LogName.Equals("")){
            $query = "SELECT LogName AS Name, COUNT(*) AS Count FROM $Table
                      WHERE TimeCreated >= '$After'
                      GROUP BY LogName
                      ORDER BY Count DESC" 
        # if a logname has been specified information will be grouped by eventid
        } elseif ($LogName -ne ""){
            $query = "SELECT EventId AS Name, COUNT(*) AS Count FROM $Table
                          WHERE LogName = '$LogName' 
                          AND TimeCreated >= '$After'
                          GROUP BY EventId
                          ORDER BY Count DESC"
        }
    }
    End
    {
        # get the query and now communicates with the database
        $result = Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query $query
                                         
        foreach ($res in $result){
            $hashTable.Add(($res.Name).tostring(),$res.Count)
        }
        Write-Output $hashTable
    }
}


<#
.NAME
   Get-HashTableForTimeLineChart

.SYNOPSIS
   Gets a hash table to be used for timeline chart.

.SYNTAX
   Get-HashTableForPieChart [[-Table <String>] [-After <String>]]

   Get-HashTableForPieChart [[-Table <String>] [-After <String>] [-LogName <String>]]

   Get-HashTableForPieChart [[-Table <String>] [-After <String>] [-LogName <String>] [-SecurityType <String>]]
   
.DESCRIPTION
   This cmdlet is used from the LogVisualization script in order to display the timeline charts.
   It implements simple group by queries to retrieve data from database.   
   
.PARAMETERS
   -Table <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -After <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -LogName <String>
    Gives to the cmdlet a string value.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -SecurityType <String>
    Gives to the cmdlet a string value.

    Required?                    false
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   [System.Collections.Hashtable]

.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-HashTableForTimeLineChart -Table EVENTS -After "06/01/2015"

   This example will output the following:

   Name                           Value
   ----                           -----
   01_Jun                         285
   02_Jun                         356
   03_Jun                         131
   04_Jun                         229
   05_Jun                         659
   06_Jun                         662
   07_Jun                         550
   08_Jun                         265
   09_Jun                         84
   10_Jun                         315
   11_Jun                         662
   12_Jun                         208
   13_Jun                         520
   14_Jun                         953
   15_Jun                         1111
   16_Jun                         1127
   17_Jun                         1075
   18_Jun                         1038
   19_Jun                         536
   20_Jun                         1032
   21_Jun                         1505
   22_Jun                         998
   23_Jun                         1139
   24_Jun                         1926
   25_Jun                         1071
   26_Jun                         1068
   27_Jun                         1036
   28_Jun                         839
   29_Jun                         900
   30_Jun                         1059
   01_Jul                         283


.EXAMPLE

   -------------------------- EXAMPLE 2 --------------------------

   PS C:\> Get-HashTableForTimeLineChart -Table EVENTS -After "02/01/2015" -LogName Security -SecurityType Failure

   This example will output the following:

   Name                           Value
   ----                           -----
   01_Feb-07_Feb                  0
   08_Feb-14_Feb                  0
   15_Feb-21_Feb                  0
   22_Feb-28_Feb                  0
   01_Mar-07_Mar                  0
   08_Mar-14_Mar                  0
   15_Mar-21_Mar                  0
   22_Mar-28_Mar                  0
   29_Mar-04_Apr                  0
   05_Apr-11_Apr                  0
   12_Apr-18_Apr                  0
   19_Apr-25_Apr                  177
   26_Apr-02_May                  1501
   03_May-09_May                  310
   10_May-16_May                  350
   17_May-23_May                  3914
   24_May-30_May                  202
   31_May-06_Jun                  674
   07_Jun-13_Jun                  299
   14_Jun-20_Jun                  1085
   21_Jun-27_Jun                  1220
   28_Jun-04_Jul                  82

#>
function Get-HashTableForTimeLineChart
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string]$Table,
        [Parameter(Mandatory=$true)]
        [string]$After,
        [string]$LogName,
        [string]$SecurityType
    )
    Begin
    {
        $hashTable = [ordered]@{}
        $DateToWorkWith = [System.DateTime]$After
        $timeSpan = New-TimeSpan -Start $DateToWorkWith -End (get-date)
    }
    Process
    {
         # gets the appropriate time ranges and then simply makes the SQL queries
        $timeRangesForNames = Get-TimeRangesForNames -DateTime $After
        $timeRangesForValues = Get-TimeRangesForValues -DateTime $After

        if ($LogName -eq ""){
            $counter = 0           
            foreach ($timeRange in $timeRangesForValues){
                $query = "SELECT COUNT(*) AS Count FROM $Table
                          WHERE (TimeCreated BETWEEN $timeRange)"

                $a = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                              -isSQLServer `
                                              -query $query).Count

                $addition = $hashTable.Add($timeRangesForNames.get($counter),$a)
                $counter++
            }
        } elseif ($LogName -ne ""){            
            if ($LogName -ne "Security"){
                $counter = 0                   
                foreach ($timeRange in $timeRangesForValues){    
                    $query = "SELECT COUNT(*) AS Count FROM $Table
                              WHERE LogName = '$LogName'
                              AND (TimeCreated BETWEEN $timeRange)"    
                    $a = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                               -isSQLServer `
                                               -query $query).Count    
                    $addition = $hashTable.Add($timeRangesForNames.get($counter),$a)
                    $counter++
                }      
            } elseif ($LogName -eq "Security"){
                if ($SecurityType -eq ""){
                    $counter = 0                        
                    foreach ($timeRange in $timeRangesForValues){
                        $query = "SELECT COUNT(*) AS Count FROM $Table
                                  WHERE LogName = '$LogName'
                                  AND (TimeCreated BETWEEN $timeRange)"        
                        $a = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                                   -isSQLServer `
                                                   -query $query).Count        
                        $addition = $hashTable.Add($timeRangesForNames.get($counter),$a)
                        $counter++
                    }
                } elseif ($SecurityType -eq "Failure"){
                    $counter = 0                       
                    foreach ($timeRange in $timeRangesForValues){
                        $query = "SELECT COUNT(*) AS Count FROM $Table
                                  WHERE LogName = '$LogName' AND EventId = 4625
                                  AND (TimeCreated BETWEEN $timeRange)"        
                        $a = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                                  -isSQLServer `
                                                  -query $query).Count
                        $addition = $hashTable.Add($timeRangesForNames.get($counter),$a)
                        $counter++
                    }
                } elseif ($SecurityType -eq "Success"){
                    $counter = 0   
                    foreach ($timeRange in $timeRangesForValues){        
                        $query = "SELECT COUNT(*) AS Count FROM $Table
                                  WHERE LogName = '$LogName' AND EventId = 4624
                                  AND (TimeCreated BETWEEN $timeRange)"        
                        $a = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                                  -isSQLServer `
                                                  -query $query).Count        
                        $addition = $hashTable.Add($timeRangesForNames.get($counter),$a)
                        $counter++
                    }
                }                
            }            
        }
     }
    End
    {        
        Write-Output $hashTable
    }
}


<#
.NAME
   Get-LogonIpAddresses

.SYNOPSIS
   Gets the ip addresses for some kinds of logon types.

.SYNTAX
   Get-LogonIpAddresses [-LogonType <String>] [-After <String>]
   
.DESCRIPTION
   This cmdlet is used from the LogVisualization script in order to display the Additional Information Panel.
   It implements simple group by queries to retrieve data from database.   
   
.PARAMETERS
   -LogonType <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

   -After <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   [System.Collections.Specialized.OrderedDictionary]
.NOTES

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-LogonIpAddresses -LogonType Failure -After "06/25/2015"

   This example will output the following:

   Name                           Value
   ----                           -----
   74.7.195.38                    173
   91.218.160.70                  173
   213.132.228.252                47
   103.55.130.162                 30
   83.212.116.67                  6
   -                              2
   64.4.124.174                   2
   66.240.236.119                 1
   200.105.154.93                 1
   83.14.193.236                  1

#>
function Get-LogonIpAddresses
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$LogonType,
        [Parameter(Mandatory=$true)]
        [string]$After
    )
    Begin
    {
        $hashTable = [ordered]@{}
    }
    Process
    {    
        if ($LogonType -eq "Failure"){
            # from table4625 : failure logon events
            $query = "SELECT SourceNetworkAddress, COUNT(*) AS Count FROM DETAILS4625
                      WHERE TimeCreated >= '$After' 
                      GROUP BY SourceNetworkAddress
                      ORDER BY Count Desc"
        } elseif($LogonType -eq "Success"){            
            # from table4624 : successful logon events
            $query = "SELECT SourceNetworkAddress, COUNT(*) AS Count FROM DETAILS4624
                      WHERE TimeCreated >= '$After' 
                      GROUP BY SourceNetworkAddress
                      ORDER BY Count Desc"
        } elseif ($LogonType -eq "Explicit"){
            # from table4648 : successful logon using explicit credentials events
            $query = "SELECT NetworkAddress, COUNT(*) AS Count FROM DETAILS4648
                      WHERE TimeCreated >= '$After' 
                      GROUP BY NetworkAddress
                      ORDER BY Count Desc"
        }       
    }
    End
    {
        # get the query and now communicates with the database
        $result = Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query $query

        if ($LogonType -eq "Failure"){
            foreach ($re in $result){
                $hashTable.Add($re.SourceNetworkAddress, $re.Count)
            }
        } elseif($LogonType -eq "Success"){
            foreach ($re in $result){
                $hashTable.Add($re.SourceNetworkAddress, $re.Count)
            }
        } elseif ($LogonType -eq "Explicit"){
            foreach ($re in $result){
                $hashTable.Add($re.NetworkAddress, $re.Count)
            }
        }        
        Write-Output $hashTable        
    }
}


<#
.NAME
   Get-TableContents

.SYNOPSIS
   Gets contents from database.

.SYNTAX
   Get-TableContents [-query [String]]
   
.DESCRIPTION
   This cmdlet is used from the LogVisualization script in order to interact with Detection Actions Panel.
   It implements any query will be retrieved from the user.
   
.PARAMETERS
   -query <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
   None

.OUTPUTS
   [Selected.System.Data.DataRow]

.NOTES
   None

#>
function Get-TableContents
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$query
    )

    Process
    {       
        $result = Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query ($query)
    }
    End
    {
        Write-Output ($result.getenumerator() | select *)
    }
}

## Second Group ## END
# cmdlets that are used only from the script: "LogVisualization.ps1"
# ==================================================================



# ==================================================================
## Third Group ## START
# cmdlets that are used only from the script: "ScheduleLogs.ps1"

<#
.NAME
   Get-LastStoredEvent

.SYNOPSIS
   Gets the last stored event from database.

.SYNTAX
   Get-LastStoredEvent [-LogName <String>]
   
.DESCRIPTION
   This cmdlet is used from the ScheduleLogs script
   in order to get information about the last stored event in database.  
   
.PARAMETERS
   -LogName <String>
    Gives to the cmdlet a string value.

    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true
    Accept wildcard characters?  false

.INPUTS
  None

.OUTPUTS
   [System.String[]]

.NOTES
   None

.EXAMPLE

   -------------------------- EXAMPLE 1 --------------------------

   PS C:\> Get-LastStoredEvent -LogName Security

   This example will output the following:
   
   Security
   57285
   07/01/2015 06:20:00


#>
function Get-LastStoredEvent
{
    [CmdletBinding()]
    [OutputType([String[]])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]$LogName
    )
    Process
    {    
        $a = Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query "SELECT TOP 1 * from EVENTS
                                         WHERE LogName = '$LogName'
                                         ORDER BY EventRecordId DESC"

        $b= $a.LogName    
        $c = [string]$a.eventrecordid
        $d = $a.timeCreated
        [String[]]$out= $b,$c, $d
        Write-Output $out      
    }
}

## Third Group ## END
# cmdlets that are used only from the script: "ScheduleLogs.ps1"
# ==================================================================


Export-ModuleMember -Variable MOLErrorLogPreference
Export-ModuleMember -Function Get-DatabaseAvailableTableNames,
                              Set-LogEventInDatabase,
                              Set-TableAutoIncrementValue,
                              Clear-TableContentsFromDatabase,
                              Get-LogonType,
                              Get-ImpersonationLevelExplanation,
                              Get-StatusExplanation,
                              Get-DatesUntilNow,
                              Get-TimeRangesForNames,
                              Get-TimeRangesForValues,                             
                              Get-TableRowNumber,
                              Get-LastEventDateFromDatabase,
                              Get-EventsOccured,
                              Get-HashTableForPieChart,
                              Get-HashTableForTimeLineChart,
                              Get-LogonIpAddresses,
                              Get-TableContents,
                              Get-LastStoredEvent  
                             