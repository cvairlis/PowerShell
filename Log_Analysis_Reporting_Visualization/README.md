# PowerShell
PowerShell stuff !!!

LOG README v1.0

Windows Event Log Analysis Visualization & Reporting using only one tool: PowerShell.

You need of course to download and install Microsoft SQL Server 2012 Expert 
download link below to choose version:
https://www.microsoft.com/en-us/download/details.aspx?id=29062

(or for the x64 ENU version you can use the following link:
http://download.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x64/SQLEXPRWT_x64_ENU.exe)


This readme will be updated in order to give clear instructions to download install and use this module.

It has been implemented for academic purpoces of University of Macedonia Thessaloniki Greece (Oct 2014-June 2015). 
Particularly it is part of my undergraduate thesis that had Information Security and System Administration concerns.

It is not finished yet. It will be updated with full documentation and comments for every cmdlet and whatever it needs.


WAY IT WORKS:

- Creating DataBase

- Saving Events in DataBase

- Auto Created Tables

- Schedule Automatic DataBase filling (JobScheduler.ps1)

- Log Visualization (LogVisualization.ps1) goes like this:
  A window appears and you can choose between History, Intraday and Custom Range visualization. 
     It automatically finds which is the last event stored date and:
     - For the last 7 days it visualizes events per Hour.
     - For dates more than 7 days it visualizes events per Day.
     - For dates more than 30 days it visualizes events per Week.

  You select time range you are interest for and you can view:
  - Pie Charts
  - Time Line Charts
  - Events Occured Number for every Event Log or for All events
  - Events Occured By Groups (for all type of view)
  - RadioButtons to view whatever you want
  - Save current chart (folder automatically is been created in the path that the script or .exe runs)
  


KEY POINTS:

- Dates Time and TimeRanges American Style

- DataBase have to re-created every new Year to contain only events occured the current year !!! 
	In other words the first event that is stored in the database have to be after 01/04/20xx.
	This is because if there are events from past years log analysis - Get-HashTableForTimeLineChart cmdlet cannot produce correct results.


