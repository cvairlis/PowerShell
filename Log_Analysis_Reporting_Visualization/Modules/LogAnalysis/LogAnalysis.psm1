$LogErrorLogPreference = 'c:\log-retries.txt'
$LogConnectionString = 
        "server=localhost\SQLEXPRESS;database=LogDB;trusted_connection=True"


Import-Module LogDatabase

<#
.NAME
   Set-LogNamesInDatabase

.SYNOPSIS
   Initiates Log Names in LogDatabase.

.SYNTAX
   Set-LogNamesInDatabase [[-InputLogName] <String[]>]
   
.DESCRIPTION
   LogDatabase (LogDB) contains a table called LOG_TYPE. 
   In order to initialize and then use the database it is good to have this table in use.
   It helps us find which eventlogs are in use, how many entries are currently stored
   for every subtable and other special information.

.PARAMETERS
   -InputLogName <String[]>
      Specifies the names of one or more Log Names to be stored in Database.
      
      Required?                    true
      Position?                    1
      Default value
      Accept pipeline input?       false
      Accept wildcard characters?  false
   
.EXAMPLE
   Set-LogNamesInDatabase -InputLogName Application, Security, System

   This is going to set these three string values in Database.

#>
function Set-LogNamesInDatabase
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        #Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String[]]$InputLogName
    )

    PROCESS {
        [long]$counter = 0
        foreach ($logname in $InputLogName) {
            
            $query = "INSERT INTO LOG_TYPE
                      (Id, LogName, Description)
                      VALUES
                      ('$counter', '$logname', '$logname Log Entries')"

            Write-Verbose "Query will be $query"
            Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                    -isSQLServer `
                                    -query $query

            $counter++
        }
    }
}



<#
.Synopsis
   Short description
.DESCRIPTION
   
   This cmdlet Clear-TableContentsFromDatabase helps you interact with the LogDatabase
   and erase the contents of a specific table. You can pass multible tables at once. See examples.
.EXAMPLE
   Clear-TableContentsFromDatabase -Table LOG_TYPE, EVENTS
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Clear-TableContentsFromDatabase
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table,

        [int]$AutoIncrementValue=0

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

            Set-TableAutoIncrementValue -Table: $ta -Value $AutoIncrementValue

            Write-Verbose "AutoIncrementValue for Table $ta will be $AutoIncrementValue."
            $AutoIncrementValue++
            Write-Verbose "The first next new record for Table: $ta will have Id value = $AutoIncrementValue"
        
        }
    }
}



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-LastEventDateFromDatabase
{
    [CmdletBinding()]
    #[OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Table,
        $After,
        $LogName,
        $SecurityType
        # Param2 help description
       
        
    )

    Begin
    {
    }
    Process
    {
        [string]$eve = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                               -isSQLServer `
                                               -query "SELECT TOP 1 TimeCreated from $Table").TimeCreated
       # Write-Output 
       $eve                                         

    }
    End
    {
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TableContentsFromDatabase
{
    [CmdletBinding()]
    #[OutputType([LogAnalysis.LogDatabase.TableContent[]])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table,
        # Param2 help description
        [int]$Newest,
        [String]$LogName,
        $SecurityType

    )
    Process
    {
        foreach ($ta in $Table){
            
            if ($LogName -eq "") {
            
                if ($Newest -eq 0){
                    <#
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                               -isSQLServer `
                                               -query "SELECT * from $ta
                                                       ORDER BY Id DESC"
                                                       #>
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                               -isSQLServer `
                                               -query "SELECT Id, EventId, LogName, TimeCreated from $ta
                                                       ORDER BY Id DESC"

                    foreach ($ev in $eve){                
                        # Creating the custom output
                        switch ($ta) {
                            "events"{                        
                            
                            $propos = @{'dBIndex'=$ev.Id;
                                              'EventId'=$ev.EventId; 
                                              'LogName'=$ev.LogName;
                                              'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                               } ;break
                            }                 
                        }     
                        $obj = New-Object -TypeName psobject -Property $propos
                        $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                        Write-Output $obj
                    }
                } else {
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                        -isSQLServer `
                                        -query "SELECT TOP $Newest * from $ta                    
                                                ORDER BY Id DESC"

                    # Database returns events (number>0)
                    # with the following foreach loop we make a custom object for each event that came from database
                
                    foreach ($ev in $eve){
                        # Creating the custom output
                        switch ($ta) {
                            "events"{
                            #[System.DateTime]$dt2 = $ev.TimeCreated

                            $propos = @{'dBIndex'=$ev.Id;
                                   'EventId'=$ev.EventId;
                                   'EventVersion'=$ev.EventVersion;
                                   'EventLevel'=$ev.EventLevel;
                                   'Task'=$ev.Task;
                                   'OpCode'=$ev.OpCode;
                                   'Keywords'=$ev.Keywords;
                                   'EventRecordId'=$ev.EventRecordId;
                                   'ProviderName'=$ev.ProviderName;
                                   'ProviderId'=$ev.ProviderId;
                                   'LogName'=$ev.LogName;
                                   'ProcessId'=$ev.ProcessId;
                                   'ThreadId'=$ev.ThreadId;
                                   'MachineName'=$ev.MachineName;
                                   'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                   'LevelDisplayName'=$ev.LevelDisplayName;
                                   'OpcodeDisplayName'=$ev.OpcodeDisplayName;
                                   'TaskDisplayName'=$ev.TaskDisplayName;
                                   'KeywordsDisplayNames'=$ev.KeywordsDisplayNames;
                                   'Message'=$ev.Message; } ;break
                            }
                        }


                        $obj = New-Object -TypeName psobject -Property $propos
                        $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                        Write-Output $obj

                
                    }
                }                         
            } elseif ($LogName -eq "Application") { 
                if ($Newest -eq 0){
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                               -isSQLServer `
                                               -query "SELECT Id, EventId, LogName, TimeCreated from $ta
                                                       WHERE LogName='Application'
                                                       ORDER BY Id DESC"
                    foreach ($ev in $eve){
                        # Creating the custom output
                        switch ($ta) {
                            "events"{
                        
                            #[System.DateTime]$dt3 = $ev.TimeCreated
    
                            $propos = @{'dBIndex'=$ev.Id;
                                              'EventId'=$ev.EventId;
                                              'LogName'=$ev.LogName;
                                              'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                              } ;break
                            } 
                
                        }  
                        
                        $obj = New-Object -TypeName psobject -Property $propos
                        $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                        Write-Output $obj                                 
                    }

                } else {
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                        -isSQLServer `
                                        -query "SELECT TOP $Newest * from $ta
                                                WHERE LogName='Application'
                                                ORDER BY Id DESC"

                    # Database returns events (number>0)
                    # with the following foreach loop we make a custom object for each event that came from database
                
                    foreach ($ev in $eve){

                
                        # Creating the custom output
                        switch ($ta) {
                            "events"{
                        
                            #[System.DateTime]$dt4 = $ev.TimeCreated

                            $propos = @{'dBIndex'=$ev.Id;
                                   'EventId'=$ev.EventId;
                                   'EventVersion'=$ev.EventVersion;
                                   'EventLevel'=$ev.EventLevel;
                                   'Task'=$ev.Task;
                                   'OpCode'=$ev.OpCode;
                                   'Keywords'=$ev.Keywords;
                                   'EventRecordId'=$ev.EventRecordId;
                                   'ProviderName'=$ev.ProviderName;
                                   'ProviderId'=$ev.ProviderId;
                                   'LogName'=$ev.LogName;
                                   'ProcessId'=$ev.ProcessId;
                                   'ThreadId'=$ev.ThreadId;
                                   'MachineName'=$ev.MachineName;
                                   'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                   'LevelDisplayName'=$ev.LevelDisplayName;
                                   'OpcodeDisplayName'=$ev.OpcodeDisplayName;
                                   'TaskDisplayName'=$ev.TaskDisplayName;
                                   'KeywordsDisplayNames'=$ev.KeywordsDisplayNames;
                                   'Message'=$ev.Message; } ;break
                            }
                
                        }                                            
                        
                        $obj = New-Object -TypeName psobject -Property $propos
                        $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                        Write-Output $obj
                    }
                }
                        
                

            } elseif ($LogName -eq "Security") {                
                if ($Newest -eq 0){

                    if ($SecurityType -eq "Failure"){
                        $eve = get-logdatabasedata -connectionstring $logconnectionstring `
                                                   -issqlserver `
                                                   -query "select Id, EventId, LogName, TimeCreated from $ta                                                       
                                                           where logname='security' and eventid = 4625
                                                           order by id desc"
                        foreach ($ev in $eve){
                            # Creating the custom output
                            switch ($ta) {
                                "events"{
                                
                                #[System.DateTime]$dt5 = $ev.TimeCreated
        
                                $propos = @{'dBIndex'=$ev.Id;
                                                'EventId'=$ev.EventId;
                                                'LogName'=$ev.LogName;
                                                'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                               } ;break
                                } 
                
                            }  
                        
                            $obj = New-Object -TypeName psobject -Property $propos
                            $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                            Write-Output $obj                           
                        }




                    } elseif ($SecurityType -eq "Success"){

                        $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                                   -isSQLServer `
                                                   -query "SELECT Id, EventId, LogName, TimeCreated from $ta                                                       
                                                           WHERE LogName='Security' AND EventId = 4624
                                                           ORDER BY Id DESC"
                        foreach ($ev in $eve){
                            # Creating the custom output
                            switch ($ta) {
                                "events"{
                                
                                #[System.DateTime]$dt5 = $ev.TimeCreated
        
                                $propos = @{'dBIndex'=$ev.Id;
                                                'EventId'=$ev.EventId;
                                                'LogName'=$ev.LogName;
                                                'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                                } ;break
                                } 
                
                            }  
                        
                            $obj = New-Object -TypeName psobject -Property $propos
                            $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                            Write-Output $obj                           
                        }



                    } elseif ($SecurityType -eq ""){
                        $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                                   -isSQLServer `
                                                   -query "SELECT * from $ta                                                       
                                                           WHERE LogName='Security'
                                                           ORDER BY Id DESC"
                        foreach ($ev in $eve){
                            # Creating the custom output
                            switch ($ta) {
                                "events"{
                                
                                #[System.DateTime]$dt5 = $ev.TimeCreated
        
                                $propos = @{'dBIndex'=$ev.Id;
                                                'EventId'=$ev.EventId;
                                                'EventVersion'=$ev.EventVersion;
                                                'EventLevel'=$ev.EventLevel;
                                                'Task'=$ev.Task;
                                                'OpCode'=$ev.OpCode;
                                                'Keywords'=$ev.Keywords;
                                                'EventRecordId'=$ev.EventRecordId;
                                                'ProviderName'=$ev.ProviderName;
                                                'ProviderId'=$ev.ProviderId;
                                                'LogName'=$ev.LogName;
                                                'ProcessId'=$ev.ProcessId;
                                                'ThreadId'=$ev.ThreadId;
                                                'MachineName'=$ev.MachineName;
                                                'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                                'LevelDisplayName'=$ev.LevelDisplayName;
                                                'OpcodeDisplayName'=$ev.OpcodeDisplayName;
                                                'TaskDisplayName'=$ev.TaskDisplayName;
                                                'KeywordsDisplayNames'=$ev.KeywordsDisplayNames;
                                                'Message'=$ev.Message; } ;break
                                } 
                
                            }  
                        
                            $obj = New-Object -TypeName psobject -Property $propos
                            $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                            Write-Output $obj                                 
                        }

                    }
                    

                } else {
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                        -isSQLServer `
                                        -query "SELECT TOP $Newest * from $ta
                                                WHERE LogName='Security'
                                                ORDER BY Id DESC"

                    # Database returns events (number>0)
                    # with the following foreach loop we make a custom object for each event that came from database
                
                    foreach ($ev in $eve){

                
                        # Creating the custom output
                        switch ($ta) {
                            "events"{
                        
                            #[System.DateTime]$dt6 = $ev.TimeCreated

                            $propos = @{'dBIndex'=$ev.Id;
                                   'EventId'=$ev.EventId;
                                   'EventVersion'=$ev.EventVersion;
                                   'EventLevel'=$ev.EventLevel;
                                   'Task'=$ev.Task;
                                   'OpCode'=$ev.OpCode;
                                   'Keywords'=$ev.Keywords;
                                   'EventRecordId'=$ev.EventRecordId;
                                   'ProviderName'=$ev.ProviderName;
                                   'ProviderId'=$ev.ProviderId;
                                   'LogName'=$ev.LogName;
                                   'ProcessId'=$ev.ProcessId;
                                   'ThreadId'=$ev.ThreadId;
                                   'MachineName'=$ev.MachineName;
                                   'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                   'LevelDisplayName'=$ev.LevelDisplayName;
                                   'OpcodeDisplayName'=$ev.OpcodeDisplayName;
                                   'TaskDisplayName'=$ev.TaskDisplayName;
                                   'KeywordsDisplayNames'=$ev.KeywordsDisplayNames;
                                   'Message'=$ev.Message; } ;break
                            }
                
                        }                                            
                        
                        $obj = New-Object -TypeName psobject -Property $propos
                        $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                        Write-Output $obj
                    }
                }




            } elseif ($LogName -eq "System") {
                
                 if ($Newest -eq 0){
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                               -isSQLServer `
                                               -query "SELECT Id, EventId, LogName, TimeCreated from $ta                                                       
                                                       WHERE LogName='System'
                                                       ORDER BY Id DESC"
                    foreach ($ev in $eve){
                        # Creating the custom output
                        switch ($ta) {
                            "events"{
                        
                            #[System.DateTime]$dt7 = $ev.TimeCreated
    
                            $propos = @{'dBIndex'=$ev.Id;
                                              'EventId'=$ev.EventId;
                                              'LogName'=$ev.LogName;
                                              'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                              } ;break
                            } 
                
                        }  
                        
                        $obj = New-Object -TypeName psobject -Property $propos
                        $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                        Write-Output $obj                                 
                    }

                } else {
                    $eve = Get-LogDatabaseData -connectionString $LogConnectionString `
                                        -isSQLServer `
                                        -query "SELECT TOP $Newest * from $ta                                                                    
                                                WHERE LogName='System'
                                                ORDER BY Id DESC"

                    # Database returns events (number>0)
                    # with the following foreach loop we make a custom object for each event that came from database
                
                    foreach ($ev in $eve){

                
                        # Creating the custom output
                        switch ($ta) {
                            "events"{
                        
                            #[System.DateTime]$dt8 = $ev.TimeCreated

                            $propos = @{'dBIndex'=$ev.Id;
                                   'EventId'=$ev.EventId;
                                   'EventVersion'=$ev.EventVersion;
                                   'EventLevel'=$ev.EventLevel;
                                   'Task'=$ev.Task;
                                   'OpCode'=$ev.OpCode;
                                   'Keywords'=$ev.Keywords;
                                   'EventRecordId'=$ev.EventRecordId;
                                   'ProviderName'=$ev.ProviderName;
                                   'ProviderId'=$ev.ProviderId;
                                   'LogName'=$ev.LogName;
                                   'ProcessId'=$ev.ProcessId;
                                   'ThreadId'=$ev.ThreadId;
                                   'MachineName'=$ev.MachineName;
                                   'TimeCreated'=[System.DateTime]$ev.TimeCreated;
                                   'LevelDisplayName'=$ev.LevelDisplayName;
                                   'OpcodeDisplayName'=$ev.OpcodeDisplayName;
                                   'TaskDisplayName'=$ev.TaskDisplayName;
                                   'KeywordsDisplayNames'=$ev.KeywordsDisplayNames;
                                   'Message'=$ev.Message; } ;break
                            }
                
                        }                                            
                        
                        $obj = New-Object -TypeName psobject -Property $propos
                        $obj.PSObject.TypeNames.Insert(0,'LogAnalysis.LogDatabase.TableContent')
                        Write-Output $obj
                    }
                }
            }
        }
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TableRowNumber
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table,
        [String]$After,
        [string]$LogName
    )
    Process
    {
        foreach ($ta in $Table){

            #$After = $After.Substring(

            if ($After -eq 0){
                  
                [int]$number = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query "SELECT COUNT(*) from $ta").item(0)

                Write-Output $number

                if ($LogName -ne ""){



                }

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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TableColumnNumber
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table
    )
    Process
    {
         foreach ($ta in $Table){
        
             Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query "select count(*)
                                         from LogDB.sys.columns
                                         where object_id=OBJECT_ID('$ta')"
        
        }
    }
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Get-DatabaseAvailableTableNames | select table_name
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-DatabaseAvailableTableNames
{
    [CmdletBinding()]
    #[OutputType([String])]
    Param
    (     
    )
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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-LogTypesFromDatabase
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
    )
    Process
    {
        Get-LogDatabaseData -connectionString $LogConnectionString `
                            -isSQLServer `
                            -query "Select * from LOG_TYPE"
    }
}





<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Get-WinEvent -LogName Application, Security, System | Sort-Object -Property TimeCreated | Set-LogEventInDatabase
.EXAMPLE
   
#>
function Set-LogEventInDatabase
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]$EventLogObject
        
    )

    Begin
    {
    }
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

        
            #Write-Verbose "It will be stored $events.Count events from $log eventlog in database."


            # antikathistw to char(') kai char(;) me keno giati yparxei provlima me thn eisagwgh sth vasi
            # an to message einai keno apla vazw to keno message sth vasi kai de kalw methodo replace!!!
            [String]$messagestr = (($ev.Message -replace "'","") -replace ";","")
            
            
            #$messagestr = $ev.Message.toString().Replace(";","")
            #$messagestr
                    
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

                #Write-Host $ev.TimeCreated
                 
            Write-Verbose "Query will be: '$query'"

            Invoke-LogDatabaseQuery -connection $LogConnectionString `
                                        -isSQLServer `
                                        -query $query



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
                        $ev.logname
                        $ev.id
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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-StatusExplanation
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Status
    )

    Begin
    {
    }
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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-LogonType
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-ImpersonationLevelExplanation
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
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
.Synopsis
   Short description
.DESCRIPTION
   Each table in database has an Id Column. Id value has an auto-increment feature for every new recond comes in.
   This cmdlet enable us to reset this value for every table inside the database.
.EXAMPLE
   Set-TableAutoIncrementValue -Table EVENTS, LOG_TYPE
.EXAMPLE
   Set-TableAutoIncrementValue -Table EVENTS -Value 8
#>
function Set-TableAutoIncrementValue
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Table,
        [int]$Value=0

      
    )

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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-CaptionFromSId
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Sid
    )
    Process
    {
        [System.Management.ManagementObject[]]$s = Get-WmiObject -Class Win32_Account
        
        foreach ($ob in $s){
            if($ob.sid -eq $Sid){
                Write-Output $ob.caption
            }        
        }
        
        if($Sid -eq "S-1-0-0"){
            Write-Output "NULL-SID"
        }
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-SecurityMessageAsObject
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.Diagnostics.Eventing.Reader.EventLogRecord]$EventLogObject
    )

    Begin
    {
    }
    Process
    {
        
    }
    End
    {
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-LastStoredEvent
{
    [CmdletBinding()]
    [OutputType([String[]])]
    Param
    (
        # Param1 help description
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


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-AllEventsGroupByLogName
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        <# Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Param1,

        # Param2 help description
        [int]
        $Param2
        #>
    )

    Begin
    {
        [System.Collections.Hashtable]$hash = [ordered]@{}
    }
    Process
    {
        $a = Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query "SELECT LogName, count(*) from EVENTS                                         
                                         GROUP BY LogName"
        
        

        foreach ($in in $a){
            $hash.add($in.logname, $in.Column1)
        }

        
        Write-Output $hash
        

    }
    End
    {
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-EventsGroupByEventId
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $LogName
    )

    Begin
    {
        [System.Collections.Hashtable]$hash = [ordered]@{}
    }
    Process
    {
        $a = Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query "SELECT EventId, count(*) from EVENTS   
                                         WHERE LogName = '$LogName'                                      
                                         GROUP BY EventId"
        
        

        foreach ($in in $a){
            $hash.add($in.eventid, $in.Column1)
        }

        
        Write-Output $hash
        
    }
    End
    {
    }
}

<#
.Synopsis
   Short description
.DESCRIPION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-HashTableForTimeLineChart
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string]$Table,
        [string]$After,
        [string]$LogName,
        [string]$SecurityType
    )

    Begin
    {
        $hashTable = [ordered]@{}
        $DateToWorkWith = [System.DateTime]$After

        # dhmiourgontas ena antikeimeno TimeSpan mporw na vrw poses meres apexei h hmeromhnia pou irthe apo th current date
        $timeSpan = New-TimeSpan -Start $DateToWorkWith -End (get-date)
       

    }
    Process
    {

         #pairnei tis katallhles ranges kai meta apla kanei ta select ths sql
         $timeRangesForNames = Get-TimeRangesForNames -DateTime $After
         $timeRangesForValues = Get-TimeRangesForValues -DateTime $After

        if ($LogName -eq ""){            
            #phre tis ranges twra kanei to erwthma kai ftiaxnei to hash table gia timeline xwris logname
            $counter = 0
            #gia kathe wra apo ta diasthmata kathe meras kanoume ena sql erwthma       
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
                #gia kathe wra apo ta diasthmata kathe meras kanoume ena sql erwthma       
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
                    #gia kathe wra apo ta diasthmata kathe meras kanoume ena sql erwthma       
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
                    #gia kathe wra apo ta diasthmata kathe meras kanoume ena sql erwthma       
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
                    #gia kathe wra apo ta diasthmata kathe meras kanoume ena sql erwthma       
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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TimeRangesForNames
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$DateTime
    )

     Begin
    {
        $namesArray = New-Object System.Collections.ArrayList
        #metatrepw to string pou irhte se antikeimeno DateTime
        $DateToWorkWith = [System.DateTime]$DateTime

        # dhmiourgontas ena antikeimeno TimeSpan mporw na vrw poses meres apexei h hmeromhnia pou irthe apo th current date
        $timeSpan = New-TimeSpan -Start $DateToWorkWith -End (get-date)
    }
    Process
    {
        # an h hmeromhnia pou irthe apo th shmerinh apexei ligoteres h ises me 7 meres (arithmos 7)
        # tote ftiakse fiasthmata ths mias wras
        if ($timeSpan.Days -lt 7){

            #gia kathe mia apo tis meres ftiakse diasthmata mias wras
            # etoima gia na xrhsimopoihthoun ws erwthma sthn sql
            for ($i = 0 ; ($i -le $timeSpan.Days); $i++){
                for ($j = 0; $j -le 23; $j++){
                    switch ($j){
                    0{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_00-01";break}
                    1{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_01-02";break}
                    2{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_02-03";break}
                    3{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_03-04";break}
                    4{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_04-05";break}
                    5{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_05-06";break}
                    6{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_06-08";break}
                    7{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_07-09";break}
                    8{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_08-10";break}
                    9{ $temp = ($DateToWorkWith.AddDays($i).ToString("dd_MMM"))+"_09-11";break}
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


        # an h hmeromhnia pou irthe apexei apo th shmerinh perissores apo 7 meres (arithmos 7) kai ligoteres apo 30
        # tote ftiakse fiasthmata ths mias meras
        } elseif ($timeSpan.Days -gt 7 -and $timeSpan.Days -le 30){
            # gia kathe mera apo th prwth mera pou irthe ftiaxnei ena str tou typou px 12_Jun mexri na ftasei th shmerinh hmeromhnia
            for ($i=0; $DateToWorkWith.AddDays($i).date -le (Get-Date).date; $i++){

                $temp = $DateToWorkWith.AddDays($i).ToString("dd_MMM")  
                $addition = $namesArray.Add($temp)
            }


        # an h hmeromhnia pou irthe apexei apo th shmerinh perissores apo 30
        # tote ftiakse fiasthmata ths mias vdomadas
        } elseif ($timeSpan.Days -gt 30){

            $weekNumber = Get-NumberOfWeekFromTheBeginningOfTime

            $template = "Week_"+$firstWeek


        }
        

        
    }
    End
    {
       
        Write-Output $namesArray
    }
    
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TimeRangesForValues
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$DateTime
    )

    Begin
    {
        $datesArray = New-Object System.Collections.ArrayList
        #metatrepw to string pou irhte se antikeimeno DateTime
        $DateToWorkWith = [System.DateTime]$DateTime

        # dhmiourgontas ena antikeimeno TimeSpan mporw na vrw poses meres apexei h hmeromhnia pou irthe apo th current date
        $timeSpan = New-TimeSpan -Start $DateToWorkWith -End (get-date)
    }
    Process
    {
        # an h hmeromhnia pou irthe apo th shmerinh apexei ligoteres h ises me 7 meres (arithmos 7)
        # tote ftiakse fiasthmata ths mias wras
        if ($timeSpan.Days -lt 7){

            #gia kathe mia apo tis meres ftiakse diasthmata mias wras
            # etoima gia na xrhsimopoihthoun ws erwthma sthn sql
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



        # an h hmeromhnia pou irthe apexei apo th shmerinh perissores apo 7 meres (arithmos 7) kai ligoteres apo 30
        # tote ftiakse fiasthmata ths mias meras
        } elseif ($timeSpan.Days -gt 7 -and $timeSpan.Days -le 30){

             for ($i=0; $DateToWorkWith.AddDays($i).date -le (Get-Date).date; $i++){
                $temp = "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 00:00:00")+"'"+" AND "+ "'"+$DateToWorkWith.AddDays($i).ToString("MM/dd/yyyy 23:59:59")+"'"
                $addition = $datesArray.Add($temp)
            }



        # an h hmeromhnia pou irthe apexei apo th shmerinh perissores apo 30
        # tote ftiakse fiasthmata ths mias vdomadas
        } elseif ($timeSpan.Days -gt 30){


        }
        

        
    }
    End
    {
        
        Write-Output $datesArray
    }
}



<#
.Synopsis
   Short description
.DESCRIPTION   Long description
   #dexetai mia hmeromhnia apo to parelthon kai epistrefei lista me oles tis hmeromhnies apo to shmera mexri tote
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-DatesUntilNow
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
        # Param1 help description
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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   http://stackoverflow.com/questions/23472027/how-is-first-day-of-week-dermined-in-powershell
#>
function Get-NumberOfWeekFromTheBeginningOfTime
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        
    )
    Process
    {
        $intDayOfWeek = (get-date).DayOfWeek.value__
        $daysToWednesday = (3 - $intDayOfWeek)
        $wednesdayCurrentWeek = (get-date).AddDays($daysToWednesday)

        # %V basically gets the amount of '7 days' that have passed this year (starting at 1)
        $week = get-date -date $wednesdayCurrentWeek -uFormat %V
        $weekNumber = ([int]::Parse($week))
        Write-Output $weekNumber

    }
    End
    {
    }
}



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-HashTableForPieChart
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string]$Table,
        [Parameter(Mandatory=$true)]
        [string]$After,
        [string]$LogName,
        [switch]$EventId
    )

    Begin
    {
        [System.Collections.Hashtable]$hashTable = [ordered]@{}
    }
    Process
    {
         # an den exei erthei logname shmainei oti tha kanei omadopoihsh ana LOGNAME kai mpainei edw 
        if ($LogName.Equals("")){
            $query = "SELECT LogName AS Name, COUNT(*) AS Count FROM $Table
                      WHERE TimeCreated >= '$After'
                      GROUP BY LogName
                      ORDER BY Count DESC"
        

        # an exei erthei logname shmainei oti thelei omadopohsh ana EVENTID ara mpainei edw
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
        #phre to query kai twra epikoinwnei me th vash
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
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-EventsOccured
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Table,
        [Parameter(Mandatory=$true)]
        [string]$After,
        [string]$LogName,
        [string]$SecurityType
    )

    Begin
    {
       # Write-Host $After
    }
    Process
    {

        # an den exei erthei logname shmainei oti ta thelei ola kai mpainei edw 
        if ($LogName.Equals("")){
            $query = "SELECT COUNT(*) AS Count FROM $Table
                      WHERE TimeCreated >= '$After'"
        

        # an exei erthei logname shmainei oti thelei mono kapoio logname ara mpainei edw
        } elseif ($LogName -ne ""){

            # an to logname pou irthe den einai security mpainei edw
            if ($LogName -ne "Security"){
                $query = "SELECT COUNT(*) AS Count FROM $Table
                          WHERE LogName = '$LogName' 
                          AND TimeCreated >= '$After'"

            # an to logname pou irthe einai security mpainei edw kai elegxei an irthei kai securitytype mazi
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
        #phre to query kai twra epikoinwnei me th vash
        $result = (Get-LogDatabaseData -connectionString $LogConnectionString `
                                 -isSQLServer `
                                 -query $query).Count
        Write-Output $result
    }
}






Export-ModuleMember -Variable MOLErrorLogPreference
Export-ModuleMember -Function Set-LogNamesInDatabase,
                              Get-LogTypesFromDatabase,
                              Set-LogEventInDatabase,
                              Get-TableContentsFromDatabase,
                              Clear-TableContentsFromDatabase,
                              Get-DatabaseAvailableTableNames,
                              Get-TableRowNumber,
                              Get-TableColumnNumber,
                              Set-TableAutoIncrementValue,
                              Get-CaptionFromSId,
                              Get-LogonType,
                              Get-LastStoredEvent,
                              Get-LastEventDateFromDatabase,
                              Get-AllEventsGroupByLogName,
                              Get-HashTableForPieChart,
                              Get-DatesUntilNow,
                              Get-HashTableForTimeLineChart,
                              Get-NumberOfWeekFromTheBeginningOfTime,
                              Get-EventsGroupByEventId,
                              Get-TimeRangesForValues,
                              Get-EventsOccured,
                              Get-TimeRangesForNames
                             