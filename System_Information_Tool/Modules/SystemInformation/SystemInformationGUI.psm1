# load the appropriate assemblies
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
Add-Type -AssemblyName System.Windows.Forms


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
function Get-SystemInformation
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
    )
    Begin
    {
        $Form = New-Object system.Windows.Forms.Form
        $menu = New-Object System.Windows.Forms.MenuStrip
        $menuAbout = New-Object System.Windows.Forms.ToolStripMenuItem
       
        $tab_control = new-object System.Windows.Forms.TabControl
        $SummaryTab = New-Object System.Windows.Forms.TabPage
        $OSTab = New-Object System.Windows.Forms.TabPage
        $CPUTab = New-Object System.Windows.Forms.TabPage
        $RAMTab = New-Object System.Windows.Forms.TabPage
        $MotherboardTab = New-Object System.Windows.Forms.TabPage
        $GraphicsTab = New-Object System.Windows.Forms.TabPage
        $HardDrivesTab = New-Object System.Windows.Forms.TabPage
        $OpticalDrivesTab = New-Object System.Windows.Forms.TabPage
        $AudioTab = New-Object System.Windows.Forms.TabPage
        $PeripheralsTab = New-Object System.Windows.Forms.TabPage
        $NetworkTab = New-Object System.Windows.Forms.TabPage
        $SWTab = New-Object System.Windows.Forms.TabPage
        
        <# SUMMARY TAB COMPONENTS #>

        $Form.Text = "System Information"
        $Form.Width = 700
        $Form.Height = 600
        $Form.MaximizeBox = $False
        $Form.StartPosition = 'CenterScreen'
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
        
        # Set the font of the text to be used within the form
        $Font = New-Object System.Drawing.Font("Calibri",12)
        $Form.Font = $Font
        
        $menuAbout.Image = [System.Drawing.SystemIcons]::Information
        $menuAbout.Text = "About"
        $menuAbout.Add_Click({About})
        #[void]$menuHelp.DropDownItems.Add($menuAbout)
        $menu.Items.Add($menuAbout)

        $Form.Controls.Add($menu)
       
        $SummaryTab.TabIndex = 0
        $SummaryTab.Text = "Summary"
        $SummaryTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $OSTab.TabIndex = 1
        $OSTab.Text = "Operating System"
        $OSTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $CPUTab.TabIndex = 2
        $CPUTab.Text = "CPU"
        $CPUTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $RAMTab.TabIndex = 3
        $RAMTab.Text = "RAM"
        $RAMTab.BackColor = [System.Drawing.Color]::WhiteSmoke
        
        $MotherboardTab.TabIndex = 4
        $MotherboardTab.Text = "Motherboard"
        $MotherboardTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $HardDrivesTab.TabIndex = 5
        $HardDrivesTab.Text = "Hard Drives"
        $HardDrivesTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $OpticalDrivesTab.TabIndex = 6
        $OpticalDrivesTab.Text = "Optical Drives"
        $OpticalDrivesTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $AudioTab.TabIndex = 7
        $AudioTab.Text = "Audio"
        $AudioTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $PeripheralsTab.TabIndex = 8
        $PeripheralsTab.Text = "Peripherals"
        $PeripheralsTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $NetworkTab.TabIndex = 9
        $NetworkTab.Text = "Network"
        $NetworkTab.BackColor = [System.Drawing.Color]::WhiteSmoke

        $SWTab.TabIndex = 10
        $SWTab.Text = "Software Installed"
        $SWTab.BackColor = [System.Drawing.Color]::WhiteSmoke

                       
        $tab_control.Controls.Add($SummaryTab)
        $tab_control.Controls.Add($OSTab)
        $tab_control.Controls.Add($CPUTab)
        $tab_control.Controls.Add($RAMTab)
        $tab_control.Controls.Add($MotherboardTab)
        $tab_control.Controls.Add($HardDrivesTab)
        $tab_control.Controls.Add($OpticalDrivesTab)
        $tab_control.Controls.Add($PeripheralsTab)
        $tab_control.Controls.Add($AudioTab)
        $tab_control.Controls.Add($NetworkTab)
        $tab_control.controls.Add($SWTab)

        $tab_control.Size = '681, 535'
        $tab_control.Location = '0, 23'
        $tab_control.TabIndex = 0
       
        $Form.Controls.Add($tab_control)

        $dialogResult = $Form.ShowDialog()


        
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
.LINKS
   https://adminscache.wordpress.com/2014/08/03/powershell-winforms-menu/
#>
function About
{
    # About Form Objects
    $aboutForm          = New-Object System.Windows.Forms.Form
    $aboutFormExit      = New-Object System.Windows.Forms.Button
    $aboutFormNameLabel = New-Object System.Windows.Forms.Label
    $aboutFormText      = New-Object System.Windows.Forms.Label
 
    # About Form
    $aboutForm.AcceptButton  = $aboutFormExit
    $aboutForm.CancelButton  = $aboutFormExit
    $aboutForm.ClientSize    = "350, 110"
    $aboutForm.ControlBox    = $false
    $aboutForm.ShowInTaskBar = $false
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.Text          = "About SystemInformation.psm1"
    $aboutForm.Add_Load($aboutForm_Load)
 
    # About Name Label
    $aboutFormNameLabel.Font     = New-Object Drawing.Font("Microsoft Sans Serif", 9, [System.Drawing.FontStyle]::Bold)
    $aboutFormNameLabel.Location = "110, 20"
    $aboutFormNameLabel.Size     = "200, 18"
    $aboutFormNameLabel.Text     = "System Information Tool"
    $aboutForm.Controls.Add($aboutFormNameLabel)
 
    # About Text Label
    $aboutFormText.Location = "100, 40"
    $aboutFormText.Size     = "300, 30"
    $aboutFormText.Text     = "          Vairlis Charalabos `n`r      GreekITedu.blogspot.gr"
    $aboutForm.Controls.Add($aboutFormText)
 
    # About Exit Button
    $aboutFormExit.Location = "135, 70"
    $aboutFormExit.Text     = "OK"
    $aboutForm.Controls.Add($aboutFormExit)
 
    [void]$aboutForm.ShowDialog()
}


Export-ModuleMember -Function Get-SystemInformation