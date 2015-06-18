<# This script created in order to create a Scheduled Job for filling the DataBase every 10 minutes.
   Actually every 10 minutes calls ScheduleLogs.ps1 and this is doing the job.
   When you will run the script you will be prompt for credential. 
   After this you can go to Task Scheduler from Administrative Tools to check if the job appears there.  #>


# Change these three variables to whatever you want
$jobname = "Automate Log Database Filling"

# Here is where your ScheduleLogs.ps1 script exists.
$script =  "C:\Users\Administrador\Documents\GitHub\PowerShell\Log_Analysis_Reporting_&_Visualization\Modules\LogAnalysis\ScheduleLogs.ps1"
$repeat = (New-TimeSpan -Minutes 10)
 

# The script below will run as the specified user (you will be prompted for credentials)
# and is set to be elevated to use the highest privileges.
# In addition, the task will run every 10 minutes or however long specified in $repeat.
$scriptblock = [scriptblock]::Create($script)
#$trigger = New-JobTrigger -AtStartup -RepeatIndefinitely -RepetitionInterval $repeat
$trigger = New-JobTrigger -Once -At (Get-Date).Date -RepeatIndefinitely -RepetitionInterval $repeat
$msg = "Enter the username and password that will run the task"
$credential = $Host.UI.PromptForCredential("Task username and password",$msg,"$env:userdomain\$env:username",$env:userdomain)


$options = New-ScheduledJobOption -RunElevated -ContinueIfGoingOnBattery -StartIfOnBattery -HideInTaskScheduler
Register-ScheduledJob -Name $jobname -ScriptBlock $scriptblock -Trigger $trigger -ScheduledJobOption $options -Credential $credential

#after this go to task scheduler to check if the job appears there




