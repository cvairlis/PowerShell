function New-CredentialObject {
param(
	[string]$UserName,
	[string]$ProtectedPassword
)
	New-Object System.Management.Automation.PSCredential $UserName, ($ProtectedPassword | ConvertTo-SecureString)
}

function Protect-String {
param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[string]$String
)
PROCESS {
	$String | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
}
}









# Change these three variables to whatever you want
$jobname = "Automate Log Database Filling"
$script =  "C:\Users\Administrador\Documents\WindowsPowerShell\Modules\LogAnalysis\ScheduleLogs.ps1"
$repeat = (New-TimeSpan -Minutes 10)
 

# The script below will run as the specified user (you will be prompted for credentials)
# and is set to be elevated to use the highest privileges.
# In addition, the task will run every 5 minutes or however long specified in $repeat.
$scriptblock = [scriptblock]::Create($script)
#$trigger = New-JobTrigger -AtStartup -RepeatIndefinitely -RepetitionInterval $repeat
$trigger = New-JobTrigger -Once -At (Get-Date).Date -RepeatIndefinitely -RepetitionInterval $repeat
$msg = "Enter the username and password that will run the task"
$credential = $Host.UI.PromptForCredential("Task username and password",$msg,"$env:userdomain\$env:username",$env:userdomain)


 
$options = New-ScheduledJobOption -RunElevated -ContinueIfGoingOnBattery -StartIfOnBattery -HideInTaskScheduler
Register-ScheduledJob -Name $jobname -ScriptBlock $scriptblock -Trigger $trigger -ScheduledJobOption $options -Credential $credential

#after this go to task scheduler to check if the job appears there


