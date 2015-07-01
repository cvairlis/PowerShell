<#
.NAME
   Get-LogDatabaseData

.Synopsis
   Queries information from the database.
 
.DESCRIPTION
    Get-LogDatabaseData is to be used when you want to query information from the database.
    
.PARAMETERS
    -ConnectionString<String>
        Tells PowerShell how to find the database server, what database to connect to, and how to authenticate.
        You can find more connection string examples at: "http://connectionstrings.com"

        Required?                    false
        Position?                    named
        Default value                Local computer
        Accept pipeline input?       True (ByPropertyName)
        Accept wildcard characters?  false

    -isSQLServer<Switch>
        Include this switch when your connection string points to a Microsoft SQL Server.
        Omit this string for all other database server types, and PowerShell will use
        OleDB instead. You'll need to make sure your connection string is OleDB compatible
        and that you're installed the necessary OleDB drivers to access your databse.
        That can be MySQL, Access, Oracle, or whatever you like.

    -Query<String>
        This is the actual SQL language query that you want to run. 
        This module isn't going to dive into detail on that language; we assume you know it already.
        If you'd like to learn more about the SQL language, there are numerous books and videos on the subject.
.NOTES
    Get-LogDatabaseData will retrieve data and place it into the pipeline.
    Within the pipeline, you'get objects with properties that correspond to the columns of the database.
    We're not going to dive into further detail on how the two database functions:
    (Get-LogDatabaseData & Invoke-LogDatabaseQuery) operate internally.
    These functions internally utilize the .NET Frameworkm and so for this module they're out of scope.
    The functions do, however, provide a nice wrapper around .NET, so that you can access databases
    without having to mess around with the raw .NET Framework stuff.

#>
function Get-LogDatabaseData
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
       [String]$connectionString,
       [String]$query,
       [switch]$isSQLServer
    )
    if ($isSQLServer) {
        Write-Verbose 'in SQL Server mode'
        $connection = New-Object -TypeName `
            System.Data.SqlClient.SqlConnection    
    } else {
        Write-Verbose 'in OleDB mode'
        $connection = New-Object -TypeName `
            System.Data.OleDb.OleDbConnection
    }

    $connection.ConnectionString = $connectionString
    $command = $connection.CreateCommand()
    $command.CommandText = $query
   
    if ($isSQLServer) {
        $adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
    } else {
        $adapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter $command
    }

    $dataset = New-Object -TypeName System.Data.DataSet
    #I put in var a to prevent to return an int value
    $a = $adapter.Fill($dataset)
    $connection.Close()
}

<#
.Name 
   Invoke-LogDatabaseQuery

.Synopsis
   Make changes on the database.

.DESCRIPTION
   Invoke-LogDatabaseQuery is for when you want to make changes on the database.
   You can add, remove or change data.

.PARAMETERS
    -ConnectionString<String>
        Tells PowerShell how to find the database server, what database to connect to, and how to authenticate.
        You can find more connection string examples at: "http://connectionstrings.com"

        Required?                    false
        Position?                    named
        Default value                Local computer
        Accept pipeline input?       True (ByPropertyName)
        Accept wildcard characters?  false

    -isSQLServer<Switch>
        Include this switch when your connection string points to a Microsoft SQL Server.
        Omit this string for all other database server types, and PowerShell will use
        OleDB instead. You'll need to make sure your connection string is OleDB compatible
        and that you're installed the necessary OleDB drivers to access your databse.
        That can be MySQL, Access, Oracle, or whatever you like.

    -Query<String>
        This is the actual SQL language query that you want to run. 
        This module isn't going to dive into detail on that language; we assume you know it already.
        If you'd like to learn more about the SQL language, there are numerous books and videos on the subject.

.NOTES
    Invoke-LogDatabaseQuery doesn't write anything to the pipeline; it just runs your query.
    It also declares support for the -WhatIf and -Confirm parameterns via its SupportsShouldProcess attribute.

#>
function Invoke-LogDatabaseQuery
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='Low')]    
    Param
    (
        [string]$connectionString,
        [string]$query,
        [switch]$isSQLServer
    )
    if ($isSQLServer) {
        Write-Verbose 'in SQL Server mode'
        $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    } else {
        Write-Verbose 'in OleDB mode'
        $connection = New-Object -TypeName System.Data.OleDb.OleDbConnection
    }
    $connection.ConnectionString = $connectionString
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    if ($pscmdlet.shouldprocess($query)) {
        $connection.Open()
        Write-Verbose $query
        # ExecuteNonQuery: Executes a Transact-SQL statement against the connection and returns the number of rows affected.
        $returnValue = $command.ExecuteNonQuery()
        $connection.close()
    }
}