$LogErrorLogPreference = 'c:\log-retries.txt'
$LogConnectionString = 
        "server=localhost\SQLEXPRESS;database=LogDB;trusted_connection=True"


#Import-Module LogDatabase
# remove and then import to be sure we have the latest changes in memory

Remove-Module LogAnalysis
Import-Module LogAnalysis


[void][Reflection.Assembly]::LoadWithPartialName("LogAnalysis.LogDatabase.TableContent")

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
        [System.DateTime]$DateTime
    )

    Begin
    {
        $DatesArray = New-Object System.Collections.ArrayList
        [int]$co = 0
    }
    Process
    {        
        while ((Get-Date).AddDays($co) -ge $DateTime) {
            $forDay = (Get-Date).AddDays($co)
            $ArrayListAddition = $DatesArray.Add($forDay)

            $co = $co-1

        }     
        $DatesArray.Reverse()
    }
    End
    {        
        Write-Output $DatesArray
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
function Get-LogVisualization
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
         # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string]$AfterDate,
        $Type
        
    )

    Begin
    {
    
        Add-Type -AssemblyName System.Windows.Forms
        $StartForm = New-Object system.Windows.Forms.Form


        $StartForm.Text = "Preparing events"
        $StartForm.Width = 450
        $StartForm.Height = 180
        $StartForm.MaximizeBox = $False
        $StartForm.StartPosition = 'CenterScreen'
        $StartForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
        $StartForm.BackColor = [System.Drawing.Color]::WhiteSmoke
        
        $Status = New-Object System.Windows.Forms.Label
        $Status.Size = '400, 30'
        $Status.Location = '5,20'
        $Status.Text = "Ready?"
        $Status.Font = New-Object System.Drawing.Font("Calibri",15)
        $StartForm.Controls.Add($Status)
        
        $ProcButton = New-Object System.Windows.Forms.Button
        $ProcButton.Text = "Yes"
        $ProcButton.Font = New-Object System.Drawing.Font("Calibri",15)
        $ProcButton.size = '60,40'
        $ProcButton.Location = '195,85'

        $StartForm.Controls.Add($ProcButton)
     

           
       
        $ProcButton.Add_Click({

            
            $ProcButton.Enabled = $false

            # proetoimasia dedomenwn gia to textbox EVENTS OCCURED
            $Status.Text = "Preparing events..."
            $StartForm.Refresh()

            $Status.Text = "Preparing all events..."
            $StartForm.Refresh()

            $Status.Text = "Counting events..."
            $StartForm.Refresh()
            $Global:AllDataEventsOccured = Get-EventsOccured -Table EVENTS -After $AfterDate
            $Global:AppDataEventsOccured = Get-EventsOccured -Table EVENTS -After $AfterDate -LogName Application
            $Global:SecDataEventsOccured = Get-EventsOccured -Table EVENTS -After $AfterDate -LogName Security
            $Global:SecSuccDataEventsOccured = Get-EventsOccured -Table EVENTS -After $AfterDate -LogName Security -SecurityType Success
            $Global:SecFailDataEventsOccured = Get-EventsOccured -Table EVENTS -After $AfterDate -LogName Security -SecurityType Failure
            $Global:SysDataEventsOccured = Get-EventsOccured -Table EVENTS -After $AfterDate -LogName System

            $Status.Text = "Preparing pie charts: All Events..."
            $StartForm.Refresh()
            # proetoimasia dedomenwn gia textarea EVENTS GROUP PIES

            $Global:AllDataGroupByLogName = Get-HashTableForPieChart -Table EVENTS -After $AfterDate
            $Status.Text = "Preparing pie charts: Application..."
            $StartForm.Refresh()
            $Global:AppDataGroupByEventId = Get-HashTableForPieChart -Table EVENTS -After $AfterDate -LogName Application
            $Status.Text = "Preparing pie charts: Security..."
            $StartForm.Refresh()
            $Global:SecDataGroupByEventId = Get-HashTableForPieChart -Table EVENTS -After $AfterDate -LogName Security
            $Status.Text = "Preparing pie charts: System..."
            $StartForm.Refresh()
            $Global:SysDataGroupByEventId = Get-HashTableForPieChart -Table EVENTS -After $AfterDate -LogName System



            # proetoimasia dedomenwn gia textarea EVENTS GROUP TIMELINES
            $Status.Text = "Preparing time line charts: All Events..."
            $StartForm.Refresh()

            $Global:AllDataTimeLine = Get-HashTableForTimeLineChart -Table EVENTS -After $AfterDate
            $Status.Text = "Preparing time line charts: Application..."
            $StartForm.Refresh()
            $Global:AppDataTimeLine = Get-HashTableForTimeLineChart -Table EVENTS -After $AfterDate -LogName Application
            $Status.Text = "Preparing time line charts: Security..."
            $StartForm.Refresh()
            $Global:SecDataTimeLine = Get-HashTableForTimeLineChart -Table EVENTS -After $AfterDate -LogName Security
            $Status.Text = "Preparing time line charts: Failure Logons..."
            $StartForm.Refresh()
            $Global:SecSuccDataTimeLine = Get-HashTableForTimeLineChart -Table EVENTS -After $AfterDate -LogName Security -SecurityType Success
            $Status.Text = "Preparing time line charts: Successful Logons..."
            $StartForm.Refresh()
            $Global:SecFailDataTimeLine = Get-HashTableForTimeLineChart -Table EVENTS -After $AfterDate -LogName Security -SecurityType Failure
            $Status.Text = "Preparing time line charts: System..."
            $StartForm.Refresh()
            $Global:SysDataTimeLine = Get-HashTableForTimeLineChart -Table EVENTS -After $AfterDate -LogName System

            $Status.Text = "Preparing events: Done..."
            $StartForm.Refresh()
            $close = $StartForm.close()
                
        })
    
        

        

        

        $show = $StartForm.ShowDialog()
         <# Preparing all information to be ready for visualization #>
        
     
              
       
        
       
       
    }
    Process
    {
        # load the appropriate assemblies
        [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
        Add-Type -AssemblyName System.Windows.Forms
        $Form = New-Object system.Windows.Forms.Form


        $Form.Text = "Log Visualization"
        $Form.Width = 1200
        $Form.Height = 700
        $Form.MaximizeBox = $False
        $Form.StartPosition = 'CenterScreen'
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
        $Form.BackColor = [System.Drawing.Color]::CornflowerBlue

        # Set the font of the text to be used within the form
        $Font = New-Object System.Drawing.Font("Calibri",15)
        
        $Form.Font = $Font

       

        $panel1 = New-Object System.Windows.Forms.TabPage
        $panel1.Size = '1191,667'
        #$panel1.Location = '40,22'
        $panel1.TabIndex = 0
        $panel1.Text = "Log Analysis Results 1"
        $panel1.BackColor = [System.Drawing.Color]::WhiteSmoke

        $panel2 = New-Object System.Windows.Forms.TabPage
        $panel2.Size = '1191,667'
        #$panel2.Location = '40,22'
        $panel2.TabIndex = 1
        $panel2.Text = "Log Analysis Results 2"
        $panel2.BackColor = [System.Drawing.Color]::WhiteSmoke

        $panel3 = New-Object System.Windows.Forms.TabPage
        $panel3.Size = '1191,667'
        #$panel2.Location = '40,22'
        $panel3.TabIndex = 2
        $panel3.Text = "Log Analysis Actions"
        $panel3.BackColor = [System.Drawing.Color]::WhiteSmoke

        $tab_control = new-object System.Windows.Forms.TabControl
        $tab_control.Controls.Add($panel1)
        $tab_control.Controls.Add($panel2)
        $tab_control.Controls.Add($panel3)
        $tab_control.Size = '1191,667'
        $tab_control.TabIndex = 0


        $Form.Controls.Add($tab_control)

        $TypeOfViewGroupBox = New-Object System.Windows.Forms.GroupBox
        $TypeOfViewGroupBox.Location = '15,10'
        $TypeOfViewGroupBox.Size = '180,160'
        $TypeOfViewGroupBox.Text = "Type of view:"

        $HistoryRadioButton = New-Object System.Windows.Forms.RadioButton
        $HistoryRadioButton.Location = '20,30'
        $HistoryRadioButton.Size = '100,30'
        $HistoryRadioButton.Text = "History"
        #$HistoryRadioButton.Checked = $true
        $HistoryRadioButton.Name = "history"

       

        $IntradayRadioButton = New-Object System.Windows.Forms.RadioButton
        $IntradayRadioButton.Location = '20,60'
        $IntradayRadioButton.Size = '100,30'
        $IntradayRadioButton.Text = "Intraday"
        $IntradayRadioButton.Name = "intraday"

        $CustomRangeRadioButton = New-Object System.Windows.Forms.RadioButton
        $CustomRangeRadioButton.Location = '20,90'
        $CustomRangeRadioButton.Size = '145,30'
        $CustomRangeRadioButton.Text = "Custom Range"
        $CustomRangeRadioButton.Name = "custom"

        # Add the GroupBox controls
        $TypeOfViewGroupBox.Controls.Add($HistoryRadioButton)
        $TypeOfViewGroupBox.Controls.Add($IntradayRadioButton)
        $TypeOfViewGroupBox.Controls.Add($CustomRangeRadioButton)
        $TypeOfViewGroupBox.Enabled = $false

        #to TypeOfViewGroupBox topotheteitai sth forma
        $panel1.Controls.Add($TypeOfViewGroupBox)

        # analoga me to poios typos optikopoihshs irthe epilegei to antistoixo koumpi
        # kai thetei ta ypoloipa anenerga
        if ($Type.Equals("History")) {
            $HistoryRadioButton.Checked = $true
            $TypeOfViewGroupBox.Enabled = $false        
        } elseif ($Type.Equals("Intraday")) {
            $IntradayRadioButton.Checked = $true
            $TypeOfViewGroupBox.Enabled = $false  
        } elseif ($Type.Equals("Custom")) {
            $CustomRangeRadioButton.Checked = $true
            $TypeOfViewGroupBox.Enabled = $false  
        }


        # Create a group that will contain Type of Chart radio buttons
        $TypeOfChartGroupBox = New-Object System.Windows.Forms.GroupBox
        $TypeOfChartGroupBox.Location = '230,10'
        $TypeOfChartGroupBox.Size = '200,120'
        $TypeOfChartGroupBox.Text = "Select type of chart:"

        # Creating the collection of chart radio buttons
        $PieRadioButton = New-Object System.Windows.Forms.RadioButton
        $PieRadioButton.Location = '40,35'
        $PieRadioButton.Size = '100,30'
        $PieRadioButton.Text = "Pie"
        $PieRadioButton.Checked = $true
        $PieRadioButton.Name = "pie"

       

        $TimeLineRadioButton = New-Object System.Windows.Forms.RadioButton
        $TimeLineRadioButton.Location = '40,70'
        $TimeLineRadioButton.Size = '100,30'
        $TimeLineRadioButton.Text = "Timeline"
        $TimeLineRadioButton.Name = "timeline"
         
        # Add the GroupBox controls
        $TypeOfChartGroupBox.Controls.Add($PieRadioButton)
        $TypeOfChartGroupBox.Controls.Add($TimeLineRadioButton)

        #to TypeOfViewGroupBox topotheteitai sth forma
        $panel1.Controls.Add($TypeOfChartGroupBox)



        $LogNameGroupBox = New-Object System.Windows.Forms.GroupBox
        $LogNameGroupBox.Location = '670,10'
        $LogNameGroupBox.Size = '200,135'
        $LogNameGroupBox.Text = "Select LogName:"



        $AllEventsRadioButton = New-Object System.Windows.Forms.RadioButton
        $AllEventsRadioButton.Location = '10,25'
        $AllEventsRadioButton.Size = '130,20'
        $AllEventsRadioButton.Text = "All events"
        $AllEventsRadioButton.Checked = $true
        $AllEventsRadioButton.Name = "allEvents"

        $LogNameGroupBox.Controls.Add($AllEventsRadioButton)


        $ApplicationEventsRadioButton = New-Object System.Windows.Forms.RadioButton
        $ApplicationEventsRadioButton.Location = '10,52'
        $ApplicationEventsRadioButton.Size = '185,23'
        $ApplicationEventsRadioButton.Text = "Application events"
        #$ApplicationEventsRadioButton.Checked = $true
        $ApplicationEventsRadioButton.Name = "appEvents"


        $SecurityEventsRadioButton = New-Object System.Windows.Forms.RadioButton
        $SecurityEventsRadioButton.Location = '10,81'
        $SecurityEventsRadioButton.Size = '185,23'
        $SecurityEventsRadioButton.Text = "Security events"
        #$ApplicationEventsRadioButton.Checked = $true
        $SecurityEventsRadioButton.Name = "secEvents"

        
        $SystemEventsRadioButton = New-Object System.Windows.Forms.RadioButton
        $SystemEventsRadioButton.Location = '10,109'
        $SystemEventsRadioButton.Size = '185,23'
        $SystemEventsRadioButton.Text = "System events"
        #$ApplicationEventsRadioButton.Checked = $true
        $SystemEventsRadioButton.Name = "sysEvents"

       
        $LogNameGroupBox.Controls.Add($AllEventsRadioButton)
        $LogNameGroupBox.Controls.Add($ApplicationEventsRadioButton)
        $LogNameGroupBox.Controls.Add($SecurityEventsRadioButton)
        $LogNameGroupBox.Controls.Add($SystemEventsRadioButton)

        $panel1.Controls.Add($LogNameGroupBox)


        # Label for the available machines combobox
        $MachinesLabel = New-Object system.windows.forms.label
        $MachinesLabel.Text = "Select Machine:"
        $MachinesLabel.Size = '140,20'
        $MachinesLabel.Location = '450,20'
        
        $panel1.Controls.Add($MachinesLabel)
        
        # Create a comboBox list that will contain Available Machines
        $MachinesComboBox = New-Object System.Windows.Forms.ComboBox
        $MachinesComboBox.Location = '450,50'
        $MachinesComboBox.Size = '200,120'
        #$MachinesComboBox.Text = "Select machine:"
        $MachinesComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList


        [String[]]$machines = "snf-654527"

        foreach ($machine in $machines){
            # putting in variable to prevent from output to console
            $m = $MachinesComboBox.Items.Add($machine)
        }

        #to TypeOfViewGroupBox topotheteitai sth forma
        $panel1.Controls.Add($MachinesComboBox)
        # sets 1st value of $machines as the default value of the combobox
        $MachinesComboBox.SelectedIndex = 0
        # Creating the collection of type of chart radio buttons
        #$TypeOfChartGroupBox = New-Object System.Windows.Forms.GroupBox


        # Label for the available security events combobox
        $SecurityEventsLabel = New-Object system.windows.forms.label
        $SecurityEventsLabel.Text = "Select Security Event:"
        $SecurityEventsLabel.Size = '190,30'
        $SecurityEventsLabel.Location = '900,20'
        
        $panel1.Controls.Add($SecurityEventsLabel)


        # Create a comboBox list that will contain Available Security Events
        $SecEventsComboBox = New-Object System.Windows.Forms.ComboBox
        $SecEventsComboBox.Location = '900,50'
        $SecEventsComboBox.Size = '200,120'
        #$MachinesComboBox.Text = "Select machine:"
        $SecEventsComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $SecEventsComboBox.Enabled = $false

        [String[]]$SecEvents = "All Security Events","Logon Failure","Logon Success"

        foreach ($ev in $SecEvents){
            # putting in variable to prevent from output to console
            $m = $SecEventsComboBox.Items.Add($ev)
        }

        #to TypeOfViewGroupBox topotheteitai sth forma
        $panel1.Controls.Add($SecEventsComboBox)
        # sets 1st value of $machines as the default value of the combobox
        $SecEventsComboBox.SelectedIndex = 0

        $SaveChartButton = New-Object System.Windows.Forms.Button
        $SaveChartButton.Location = '981,100'
        $SaveChartButton.Size = '120,30'
        $SaveChartButton.Text = "Save Chart"
        $panel1.Controls.Add($SaveChartButton)


        # Creating the collection of type of chart radio button
        # Label for the available machines combobox
        $EventsOccuredLabel = New-Object system.windows.forms.label
        $EventsOccuredLabel.Text = "Total Event Log
Events Found:"
        $EventsOccuredLabel.Size = '240,60'
        $EventsOccuredLabel.Location = '16,195'
        $EventsOccuredLabel.Font = New-object System.Drawing.Font('Calibri', 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)
        
        $panel1.Controls.Add($EventsOccuredLabel)


        $EventsOccuredTextBox = New-Object -TypeName 'System.Windows.Forms.TextBox'
        $EventsOccuredTextBox.Size = '100,40'
        $EventsOccuredTextBox.Location = '20,255'
        $EventsOccuredTextBox.ReadOnly = $true

        $EventsOccuredTextBox.Text = $Global:AllDataEventsOccured | Out-String



        


        $panel1.Controls.Add($EventsOccuredTextBox)



        $EventsGroupTextBox = New-Object System.Windows.Forms.TextBox

         # add textbox
        $EventsGroupTextBox.Multiline = $true
        $EventsGroupTextBox.Height = 300
        $EventsGroupTextBox.Width = 290
        $EventsGroupTextBox.Location ='20,310'
        $EventsGroupTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
        $EventsGroupTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
        $EventsGroupTextBox.ReadOnly = $true
        $EventsGroupTextBox.Font = New-Object System.Drawing.Font("Times New Roman",12)


        
        $EventsGroupTextBox.Text = $Global:AllDataGroupByLogName.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 30
                                   

        #$EventsGroupTextBox.Text = $AllDataGroupByLogName | sort count -Descending | Out-String

        $panel1.Controls.Add($EventsGroupTextBox)


   

        $Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $Chart.Width = 850
        $Chart.Height = 450
        $Chart.Left = 320
        $Chart.Top = 160


        # create a chartarea to draw on and add to chart
        $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $ChartArea.AxisX.Interval = 1
        $ChartArea.AxisY.Title = "Number of events"
        $ChartArea.AxisY.TitleFont =  New-Object System.Drawing.Font("Calibri",15)
        $ChartArea.AxisX.Title = "Date or Time range"
        $ChartArea.AxisX.TitleFont =  New-Object System.Drawing.Font("Calibri",15)
        $Chart.MaximumSize.Width = 20
        
        #$ChartArea.AxisX.ScrollBar = $true

        $Chart.ChartAreas.Add($ChartArea)
        

        $panel1.controls.add($Chart) 

        [void]$Chart.Series.Add("Data")
        
        $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
        $Chart.Series["Data"].BorderWidth = 3

        $Chart.Series["Data"].Points.DataBindXY($Global:AllDataGroupByLogName.Keys, $Global:AllDataGroupByLogName.Values)
      
        # set chart type
        $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
        #$Form.Activate()



        <######################>
        <# Event Handlers Start #>

        $AllEventsRadioButton.Add_Click({
            $SecEventsComboBox.Enabled = $false
            $SecEventsComboBox.SelectedIndex = 0
            $EventsOccuredTextBox.Text = $Global:AllDataEventsOccured | Out-String
            #$EventsOccuredTextBox.Text = $AppData.count | Out-String
            if ($PieRadioButton.Checked){
                $EventsGroupTextBox.Text = $Global:AllDataGroupByLogName.GetEnumerator()  | 
                                                select Name, Value |
                                                Sort-Object -Property Value -Descending  | 
                                                Out-String -Width 30
                $Chart.Series["Data"].Points.DataBindXY($Global:AllDataGroupByLogName.Keys, $Global:AllDataGroupByLogName.Values)
                $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
            } elseif($TimeLineRadioButton.Checked){
                $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                $EventsGroupTextBox.Text = $Global:AllDataTimeLine.getenumerator() |
                                                                   select Name, Value |                                               
                                                                    Out-String -Width 25
                $Chart.Series["Data"].Points.DataBindXY($Global:AllDataTimeLine.Keys, $Global:AllDataTimeLine.Values)
                $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
            }
            
        })


        $ApplicationEventsRadioButton.Add_Click({
            $SecEventsComboBox.Enabled = $false
            $SecEventsComboBox.SelectedIndex = 0
            $EventsOccuredTextBox.Text = $Global:AppDataEventsOccured | Out-String
            if ($PieRadioButton.Checked){
                $EventsGroupTextBox.Text = $Global:AppDataGroupByEventId.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 20
                
                $Chart.Series["Data"].Points.DataBindXY($Global:AppDataGroupByEventId.Keys, $Global:AppDataGroupByEventId.Values)
                $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
            } elseif($TimeLineRadioButton.Checked){
                $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                $EventsGroupTextBox.Text = $Global:AppDataTimeLine.getenumerator() |
                                                                   select Name, Value |                                               
                                                                    Out-String -Width 25
                $Chart.Series["Data"].Points.DataBindXY($Global:AppDataTimeLine.Keys, $Global:AppDataTimeLine.Values)
                $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
            }
        })


        $SecurityEventsRadioButton.Add_Click({
            $SecEventsComboBox.Enabled = $true

            switch ($SecEventsComboBox.SelectedItem) {                
                "All Security Events"{
                    $PieRadioButton.Enabled = $true
                    $EventsOccuredTextBox.Text = $Global:SecDataEventsOccured | Out-String
                    if ($PieRadioButton.Checked){
                    #edw den mpainei pote ousiastika

                       $EventsGroupTextBox.Text = $Global:SecDataGroupByEventId.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 20
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecDataGroupByEventId.Keys, $Global:SecDataGroupByEventId.Values)
                        $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie


                       
                    } elseif($TimeLineRadioButton.Checked){
                        $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                        $EventsGroupTextBox.Text = $Global:SecDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecDataTimeLine.Keys, $Global:SecDataTimeLine.Values)
                        $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    };break
                }
                "Logon Failure"{
                    $PieRadioButton.Enabled = $false
                    $PieRadioButton.Checked = $false
                    $TimeLineRadioButton.Checked = $true
                    $EventsOccuredTextBox.Text = $Global:SecFailDataEventsOccured | Out-String             
                  
                    $Chart.Series["Data"].Color = [System.Drawing.Color]::PaleVioletRed
                    $EventsGroupTextBox.Text = $Global:SecFailDataTimeLine.GetEnumerator() | 
                                                            select name,value | Out-String -Width 25
                    $Chart.Series["Data"].Points.DataBindXY($Global:SecFailDataTimeLine.Keys, $Global:SecFailDataTimeLine.Values)
                    $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    ;break
                }
                "Logon Success"{
                    $PieRadioButton.Enabled = $false
                    $PieRadioButton.Checked = $false
                    $TimeLineRadioButton.Checked = $true
                    $EventsOccuredTextBox.Text = $Global:SecSuccDataEventsOccured | Out-String
                   
                    $Chart.Series["Data"].Color = [System.Drawing.Color]::YellowGreen
                    $EventsGroupTextBox.Text = $Global:SecSuccDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                    $Chart.Series["Data"].Points.DataBindXY($Global:SecSuccDataTimeLine.Keys, $Global:SecSuccDataTimeLine.Values)
                    $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    ;break
                }
            }
        })


        $SystemEventsRadioButton.Add_Click({
            $SecEventsComboBox.Enabled = $false
            $SecEventsComboBox.SelectedIndex = 0         
            $EventsOccuredTextBox.Text = $Global:SysDataEventsOccured | Out-String
            if ($PieRadioButton.Checked){
                $EventsGroupTextBox.Text = $Global:SysDataGroupByEventId.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 20
                $Chart.Series["Data"].Points.DataBindXY($Global:SysDataGroupByEventId.Keys, $Global:SysDataGroupByEventId.Values)
                $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
            } elseif($TimeLineRadioButton.Checked){
                $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                $EventsGroupTextBox.Text = $Global:SysDataTimeLine.getenumerator() |
                                                                   select Name, Value |                                               
                                                                    Out-String -Width 25
                $Chart.Series["Data"].Points.DataBindXY($Global:SysDataTimeLine.Keys, $Global:SysDataTimeLine.Values)
                $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
            }
        })


        $PieRadioButton.add_click({
            if($AllEventsRadioButton.Checked){
                $EventsOccuredTextBox.Text = $Global:AllDataEventsOccured | Out-String
                $EventsGroupTextBox.Text = $Global:AllDataGroupByLogName.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 30
                $Chart.Series["Data"].Points.DataBindXY($Global:AllDataGroupByLogName.Keys, $Global:AllDataGroupByLogName.Values)
            } elseif ($ApplicationEventsRadioButton.Checked){
                $EventsOccuredTextBox.Text = $Global:AppDataEventsOccured | Out-String
                $EventsGroupTextBox.Text = $Global:AppDataGroupByEventId.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 20
                
                $Chart.Series["Data"].Points.DataBindXY($Global:AppDataGroupByEventId.Keys, $Global:AppDataGroupByEventId.Values)
            } elseif ($SecurityEventsRadioButton.Checked){
                switch ($SecEventsComboBox.SelectedItem) {                
                    "All Security Events"{        
                        $EventsOccuredTextBox.Text = $Global:SecDataEventsOccured | Out-String                                    
                        $EventsGroupTextBox.Text = $Global:SecDataGroupByEventId.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 20
                        
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecDataGroupByEventId.Keys, $Global:SecDataGroupByEventId.Values)                   
                    }
                }
            } elseif ($SystemEventsRadioButton.Checked){
                $EventsOccuredTextBox.Text = $Global:SysDataEventsOccured | Out-String
                $EventsGroupTextBox.Text = $Global:SysDataGroupByEventId.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 20
                
                $Chart.Series["Data"].Points.DataBindXY($Global:SysDataGroupByEventId.Keys, $Global:SysDataGroupByEventId.Values)
            }
 
             
            # set chart type
            #$Chart.Series["Data"].Points.DataBindXY($AllPieData.Keys, $AllPieData.Values)
            $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
        })

        #$timelinePressedCounter=0
        $TimeLineRadioButton.Add_Click({

            if($AllEventsRadioButton.Checked){
            
                $EventsOccuredTextBox.Text = $Global:AllDataEventsOccured | Out-String
                $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                $EventsGroupTextBox.Text = $Global:AllDataTimeLine.getenumerator() |
                                                                   select Name, Value |                                               
                                                                    Out-String -Width 25
                $Chart.Series["Data"].Points.DataBindXY($Global:AllDataTimeLine.Keys, $Global:AllDataTimeLine.Values)
                
                
            } elseif ($ApplicationEventsRadioButton.Checked){
                $EventsOccuredTextBox.Text = $Global:AppDataEventsOccured | Out-String
                $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                $EventsGroupTextBox.Text = $Global:AppDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                
                $Chart.Series["Data"].Points.DataBindXY($Global:AppDataTimeLine.Keys, $Global:AppDataTimeLine.Values)
            } elseif ($SecurityEventsRadioButton.Checked){
                switch ($SecEventsComboBox.SelectedItem) {                
                    "All Security Events"{
                        $EventsOccuredTextBox.Text = $Global:SecDataEventsOccured | Out-String
                        $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                                          
                        $EventsGroupTextBox.Text = $Global:SecDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecDataTimeLine.Keys, $Global:SecDataTimeLine.Values)
                        #$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line                               
                    }
                    "Logon Failure"{
                        $EventsOccuredTextBox.Text = $Global:SecFailDataEventsOccured | Out-String
                        $Chart.Series["Data"].Color = [System.Drawing.Color]::PaleVioletRed
                    
                        $EventsGroupTextBox.Text = $Global:SecFailDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecFailDataTimeLine.Keys, $Global:SecFailDataTimeLine.Values)
                        #$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    }
                    "Logon Success"{
                        $EventsOccuredTextBox.Text = $Global:SecSuccDataEventsOccured | Out-String
                        $Chart.Series["Data"].Color = [System.Drawing.Color]::YellowGreen
                        
                        $EventsGroupTextBox.Text = $Global:SecSuccDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecSuccDataTimeLine.Keys, $Global:SecSuccDataTimeLine.Values)
                        #$Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    }
                }
            } elseif ($SystemEventsRadioButton.Checked){
                $EventsOccuredTextBox.Text = $Global:SysDataEventsOccured | Out-String
                $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                $EventsGroupTextBox.Text = $Global:SysDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                
                $Chart.Series["Data"].Points.DataBindXY($Global:SysDataTimeLine.Keys, $Global:SysDataTimeLine.Values)
            }
    
            $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
        })

        

        # event handler for SecEventsComboBox
        $SecEventsComboBox.Add_SelectedIndexChanged({
            switch ($SecEventsComboBox.SelectedItem) {                
                "All Security Events"{
                    $PieRadioButton.Enabled = $true
                    $EventsOccuredTextBox.Text = $Global:SecDataEventsOccured | Out-String
                    if ($PieRadioButton.Checked){
                    #edw den mpainei pote ousiastika

                       $EventsGroupTextBox.Text = $Global:SecDataGroupByEventId.GetEnumerator()  | 
                                   select Name, Value |
                                   Sort-Object -Property Value -Descending  | 
                                   Out-String -Width 20
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecDataGroupByEventId.Keys, $Global:SecDataGroupByEventId.Values)
                        $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie


                       
                    } elseif($TimeLineRadioButton.Checked){
                        $Chart.Series["Data"].Color = [System.Drawing.Color]::DarkCyan
                        $EventsGroupTextBox.Text = $Global:SecDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                        $Chart.Series["Data"].Points.DataBindXY($Global:SecDataTimeLine.Keys, $Global:SecDataTimeLine.Values)
                        $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    };break
                }
                "Logon Failure"{
                    $PieRadioButton.Enabled = $false
                    $PieRadioButton.Checked = $false
                    $TimeLineRadioButton.Checked = $true
                    $EventsOccuredTextBox.Text = $Global:SecFailDataEventsOccured | Out-String             
                  
                    $Chart.Series["Data"].Color = [System.Drawing.Color]::PaleVioletRed
                    $EventsGroupTextBox.Text = $Global:SecFailDataTimeLine.GetEnumerator() | 
                                                            select name,value | Out-String -Width 25
                    $Chart.Series["Data"].Points.DataBindXY($Global:SecFailDataTimeLine.Keys, $Global:SecFailDataTimeLine.Values)
                    $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    ;break
                }
                "Logon Success"{
                    $PieRadioButton.Enabled = $false
                    $PieRadioButton.Checked = $false
                    $TimeLineRadioButton.Checked = $true
                    $EventsOccuredTextBox.Text = $Global:SecSuccDataEventsOccured | Out-String
                   
                    $Chart.Series["Data"].Color = [System.Drawing.Color]::YellowGreen
                    $EventsGroupTextBox.Text = $Global:SecSuccDataTimeLine.GetEnumerator() | select name,value | Out-String -Width 25
                    $Chart.Series["Data"].Points.DataBindXY($Global:SecSuccDataTimeLine.Keys, $Global:SecSuccDataTimeLine.Values)
                    $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
                    ;break
                }
            }
        })


        $SaveChartButton.Add_Click({
            # arxika h onomasia ksekina me stigmiotypo wras sth morfi 14-Jun-2015-21-02-55
            [string]$fileName = (get-date).ToString("dd-MMM-yyyy-HH-mm-ss_")        
            $fileName += $Type
            if ($PieRadioButton.Checked){
                if ($AllEventsRadioButton.Checked){
                    $fileName += "AllEventsPie"
                } elseif($ApplicationEventsRadioButton.Checked){
                    $fileName += "ApplicationEventsPie"
                } elseif($SecurityEventsRadioButton.Checked){
                     $fileName += "SecurityEventsPie"
                } elseif($SystemEventsRadioButton){
                     $fileName += "SystemEventsPie"
                }
            } elseif ($TimeLineRadioButton.Checked){
                if ($AllEventsRadioButton.Checked){
                    $fileName += "AllEventsTimeLine"
                } elseif($ApplicationEventsRadioButton.Checked){
                    $fileName += "ApplicationEventsTimeLine"
                } elseif($SecurityEventsRadioButton.Checked){
                    if ($SecEventsComboBox.SelectedIndex -eq 0){
                        $fileName += "AllSecurityEventsTimeLine"
                    } elseif($SecEventsComboBox.SelectedIndex -eq 1){
                        $fileName += "FailureLogonSecurityEventsTimeLine"
                    } elseif($SecEventsComboBox.SelectedIndex -eq 2){
                        $fileName += "SuccessLogonSecurityEventsTimeLine"
                    }
                } elseif($SystemEventsRadioButton){
                    $fileName += "SystemEventsTimeLine"
                }
            }
            

            [switch]$pathExists = Test-Path -Path $PSScriptRoot\chartsImages
            # elegxei an o fakelos chartsImages yparxei!
            # an den yparxei ton dhmiourgei kai vazei ekei mesa tis eikones
            if (!$pathExists){
                New-Item -ItemType Directory -Force -Path $PSScriptRoot\chartsImages 
            }
            
            $Chart.Width = 2000
            $Chart.Height = 1000
            # $PSScriptRoot: This is an automatic variable set to the current file's/module's directory
            $Chart.SaveImage("$PSScriptRoot\chartsImages\$fileName.png","png")
            $Chart.Width = 850
            $Chart.Height = 450
        })

        <# Event Handlers End #>
        <######################>





        # Get the results from the button click
        $dialogResult = $Form.ShowDialog()
        #$dialogResult
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
function Get-PreparedForVisualization
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
    <#
        # Param1 help description
        [Parameter(Mandatory=$false,
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
    }
    Process
    {
    
        # this is to start with a window that will inform the user
        # for what it will happen
        # data have to be loaded 
        $PreparingDataForm = New-Object System.Windows.Forms.Form

        $PreparingDataForm.Text = "Preparing Log Data"
        $PreparingDataForm.Width = 500
        $PreparingDataForm.Height = 480
        $PreparingDataForm.MaximizeBox = $False
        $PreparingDataForm.StartPosition = 'CenterScreen'
        $PreparingDataForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
        $PreparingDataForm.BackColor = [System.Drawing.Color]::LightCyan



        $EventsFoundLabel = New-Object system.windows.forms.label
        $EventsFoundLabel.Text = "Total Event Log Events Found:"
        $EventsFoundLabel.Size = '312,30'
        $EventsFoundLabel.Location = '22,10'
        $EventsFoundLabel.Font = New-object System.Drawing.Font('Calibri', 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)
        
        $PreparingDataForm.Controls.Add($EventsFoundLabel)


        
        $EventsFoundTextBox = New-Object -TypeName 'System.Windows.Forms.TextBox'
        $EventsFoundTextBox.Size = '100,20'
        $EventsFoundTextBox.Location = '340,10'
        $EventsFoundTextBox.Font = New-Object System.Drawing.Font("Times New Roman",16)
        $EventsFoundTextBox.ReadOnly = $true
        
        $EventsFoundTextBox.Text = Get-TableRowNumber -Table events | Out-String

        $PreparingDataForm.Controls.Add($EventsFoundTextBox)



         # Label for the available machines combobox
        $InformationLabel = New-Object system.windows.forms.label
        $InformationLabel.Text = "Getting data from the Database maybe will take more than few seconds depending on the size of the available data that is stored in the Database."
        $InformationLabel.Size = '450,40'
        $InformationLabel.Location = '22,50'
        $InformationLabel.Font = New-object System.Drawing.Font('Calibri', 10, [System.Drawing.FontStyle]::Italic, [System.Drawing.GraphicsUnit]::Point,0)
        
        $PreparingDataForm.Controls.Add($InformationLabel)




        # Label for the available machines combobox
        $ProceedLabel = New-Object system.windows.forms.label
        $ProceedLabel.Text = "Proceed by choosing a time range to get the data and then press the Proceed to Visualization button and the progress bar will display the current progress of the retrieving and preparing data procedure."
        $ProceedLabel.Size = '400,80'
        $ProceedLabel.Location = '22,90'
        $ProceedLabel.Font = New-object System.Drawing.Font('Calibri', 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)
        
        $PreparingDataForm.Controls.Add($ProceedLabel)

        # Add Button
        $ProceedButton = New-Object System.Windows.Forms.Button
        $ProceedButton.Location = New-Object System.Drawing.Size(165,380)
        $ProceedButton.Font = New-object System.Drawing.Font('Calibri', 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)
        $ProceedButton.BackColor = [System.Drawing.Color]::Gray
        $ProceedButton.ForeColor = [System.Drawing.Color]::Black
        $ProceedButton.Size = New-Object System.Drawing.Size(150,53)
        $ProceedButton.Text = "Proceed To
Visualization"

        
        $PreparingDataForm.Controls.Add($ProceedButton)

       
        $RangeGroupBox = New-Object System.Windows.Forms.GroupBox
        $RangeGroupBox.Location = '30,187'
        $RangeGroupBox.Size = '200,120'
        $RangeGroupBox.Text = "Select time range:"
        $RangeGroupBox.Font = New-object System.Drawing.Font('Calibri', 14, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)

        $HistoryRangeRadioButton = New-Object System.Windows.Forms.RadioButton
        $HistoryRangeRadioButton.Location = '40,25'
        $HistoryRangeRadioButton.Size = '100,30'
        $HistoryRangeRadioButton.Text = "History"
        $HistoryRangeRadioButton.Checked = $true
        $HistoryRangeRadioButton.Name = "history"
        $HistoryRangeRadioButton.Font = New-object System.Drawing.Font('Calibri', 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)

       

        $IntradayRangeRadioButton = New-Object System.Windows.Forms.RadioButton
        $IntradayRangeRadioButton.Location = '40,53'
        $IntradayRangeRadioButton.Size = '100,30'
        $IntradayRangeRadioButton.Text = "Intraday"
        $IntradayRangeRadioButton.Name = "intraday"
        $IntradayRangeRadioButton.Font = New-object System.Drawing.Font('Calibri', 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)

      
        $CustomRangeRadioButton = New-Object System.Windows.Forms.RadioButton
        $CustomRangeRadioButton.Location = '40,82'
        $CustomRangeRadioButton.Size = '130,30'
        $CustomRangeRadioButton.Text = "Custom Range"
        $CustomRangeRadioButton.Name = "custom"
        $CustomRangeRadioButton.Font = New-object System.Drawing.Font('Calibri', 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)


        # Add the GroupBox controls
        $RangeGroupBox.Controls.Add($HistoryRangeRadioButton)
        $RangeGroupBox.Controls.Add($IntradayRangeRadioButton)
        $RangeGroupBox.Controls.Add($CustomRangeRadioButton)
        

        #to TypeOfViewGroupBox topotheteitai sth forma
        $PreparingDataForm.Controls.Add($RangeGroupBox)

        # Create a comboBox list that will contain Available Security Events
        


        
        # Label for the available machines combobox
        $AfterDateLabel = New-Object system.windows.forms.label
        $AfterDateLabel.Text = "After Date:"
        $AfterDateLabel.Size = '100,20'
        $AfterDateLabel.Location = '260,190'
        $AfterDateLabel.Font = New-object System.Drawing.Font('Calibri', 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)
        
        $PreparingDataForm.Controls.Add($AfterDateLabel)

        $CustomRangeListBox = New-Object System.Windows.Forms.ListBox
        $CustomRangeListBox.Location = '260,210'
        $CustomRangeListBox.Size = '150,120'
        
        $CustomRangeListBox.Enabled = $false
        
        
        $CustomRangeListBox.Font = New-object System.Drawing.Font('Calibri', 10, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point,0)
        
        #$CustomRangeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown

        $PreparingDataForm.Controls.Add($CustomRangeListBox)
       
        
        [System.DateTime]$LastEventDate = Get-LastEventDateFromDatabase -Table events
        
        $DatesArray = New-Object System.Collections.ArrayList
        
        [int]$Global:c=0
        while ((Get-Date).AddDays($c) -ge $LastEventDate) {
            $forDay = (Get-Date).AddDays($c)
            $ArrayListAddition = $DatesArray.Add($forDay.ToString("MM/dd/yyyy"))

            $c=$c-1
            #$d = (Get-Date).AddDays($c)
            
            
        }
        
        if (($LastEventDate.Day).Equals((Get-Date).AddDays($c).Day)) {
            #after this adds and the last event date
            $ArrayListAddition = $DatesArray.Add($LastEventDate.ToString("MM/dd/yyyy"))
            #$DatesArray.Count
        }

    
       

        foreach ($day in $DatesArray){
            # putting in variable to prevent from output to console
            $m = $CustomRangeListBox.Items.Add($day)
        }
        
        
        #to TypeOfViewGroupBox topotheteitai sth forma
        $PreparingDataForm.Controls.Add($CustomRangeListBox)
        # sets 1st value of $machines as the default value of the combobox
        #$CustomRangeListBox.SelectedIndex = 0
        # Creating the collection of type of chart radio button


         

        $System_Drawing_Size = New-Object System.Drawing.Size
        $System_Drawing_Size.Width = 460
        $System_Drawing_Size.Height = 30
        

        $ProgressBar = New-Object System.Windows.Forms.ProgressBar
        $ProgressBar.Name = 'Preparing Data. Please wait..'
        $ProgressBar.Value = 0
        $ProgressBar.Style="Continuous"
        $ProgressBar.Size = $System_Drawing_Size
        $ProgressBar.Left = 15
        $ProgressBar.Top = 335
        # Finally, like the other controls, the progress bar needs to be added to the form.
        $PreparingDataForm.Controls.Add($ProgressBar)


        $EventsArray = New-Object System.Collections.ArrayList

        
       
      
      
        <# Event Handlers Start #>
        <######################>




        $CustomRangeRadioButton.Add_Click({
            $CustomRangeListBox.Enabled = $true
        })


        $HistoryRangeRadioButton.Add_Click({
            $CustomRangeListBox.Enabled = $false
            $str = Get-TableRowNumber -Table events
            $EventsFoundTextBox.Text = $str
        
        })

        $IntradayRangeRadioButton.Add_Click({
            $CustomRangeListBox.Enabled = $false
            $str = Get-TableRowNumber -Table events -After (Get-Date -Format "MM/dd/yyyy 00:00:00").ToString()
            $EventsFoundTextBox.Text = $str        
        })


        $CustomRangeListBox.Add_Click({ 
            [string]$tempDate = $CustomRangeListBox.SelectedItems + " 00:00:00"
            $str = Get-TableRowNumber -Table events -After $tempDate
            $EventsFoundTextBox.Text = $str | Out-String      
        })

        $Global:Type = ""
        $i=0
        
         #Add Button event 
        $ProceedButton.Add_Click({

            if(!($EventsFoundTextBox.Text.Equals("0"))){

                $ProceedButton.Enabled = $false            
                $CustomRangeRadioButton.Enabled = $false
                $HistoryRangeRadioButton.Enabled = $false
                $IntradayRangeRadioButton.Enabled = $false
                $CustomRangeListBox.Enabled = $false

                $PreparingDataForm.Close()

            } else {
                Write-Host "Zero Events Found. Nothing can be vizualized"
            }

        })
        

        <# Event Handlers End #>
        <######################>


        $a = $PreparingDataForm.ShowDialog()
        
    }
    End
    {
        # otan o xrhsths pathsei to koumpi procceed to visualization mia apo tis parakatw times pernaei san parametros sto epomeno parathyro
        # analoga me ti epithimei na optikopoihsei (istoriko intraday h custom) h parametros einai mia hmeromhnia
        # 
        #$Global:Type = ""
        if ($HistoryRangeRadioButton.Checked) {
            $Global:Type =  "History"
            $afterDate =  Get-LastEventDateFromDatabase -Table EVENTS
        } elseif ($IntradayRangeRadioButton.Checked){
            $Global:Type =  "Intraday"
            $afterDate =  (get-date).date.ToString("MM/dd/yyyy HH:mm:ss")
        } else {
            $Global:Type =  "Custom"
            $afterDate = [string]$CustomRangeListBox.SelectedItems + " 00:00:00"
        }
        Write-Output $afterDate
    }
}



Get-LogVisualization -AfterDate (Get-PreparedForVisualization) -Type $Global:Type

















