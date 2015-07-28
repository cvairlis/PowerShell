[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
[void] [System.Reflection.Assembly]::LoadWithPartialName('System.Collections')

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
function Get-Contacts
{
    [CmdletBinding()]
    #[OutputType([int])]
    Param
    (
    )
    Begin
    {
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = "Προετοιμασία επαφών"
        $Form.Width = 450
        $Form.Height = 200
        $Form.MaximizeBox = $False
        $Form.StartPosition = 'CenterScreen'
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

        # Set the font of the text to be used within the form
        $Font = New-Object System.Drawing.Font("Calibri",16)
        $Form.Font = $Font

        $FoundLabel = New-Object System.Windows.Forms.Label
        $FoundLabel.Location = '20, 100'
        $FoundLabel.Size = '350, 30'
        $FoundLabel.Text = 'Γίνεται σάρωση αρχείων CSV...'
        $Form.Controls.Add($FoundLabel)

        $ParseLabel = New-Object System.Windows.Forms.Label
        $ParseLabel.Location = '20, 60'
        $ParseLabel.Size = '300, 30'
        $Form.Controls.Add($ParseLabel)

        $WaitLabel = New-Object System.Windows.Forms.Label
        $WaitLabel.Location = '20, 20'
        $WaitLabel.Size = '300, 30'
        $Form.Controls.Add($WaitLabel)

        <#
        # For EXE USE THIS 
        [switch]$pathExists = Test-Path -Path ((Get-Location).Path+"\exportedData")
        #FOR EXE USE THIS 
        $path = (Get-Location).Path+"\exportedData"
        # elegxei an o fakelos exportedData yparxei!
        # an den yparxei ton dhmiourgei kai vazei ekei mesa tis ta csv kai ta html
        if (!$pathExists){
            New-Item -ItemType Directory -Force -Path $path
        }
        #>  
                
        # check file exist link:
        # https://technet.microsoft.com/en-us/library/ff730955.aspx
        # FOR SCRIPT USE THIS 
        [switch]$CsvExists = Test-Path -Path $PSScriptRoot\* -Include *.csv       
        if (!$CsvExists){
            Write-Host "de vrethike arxeio csv"
            $FoundLabel.Text = 'Δε βρέθηκαν αρχεία CSV για σάρωση.'
        } else {
            # measure csv files found
            $CsvCounter = (Get-ChildItem -Path $PSScriptRoot\*.csv | Measure-Object ).Count
            if ($CsvCounter -eq 1){
                $FoundLabel.Text = 'Βρέθηκαν' + " $CsvCounter " + 'αρχείο CSV για σάρωση.'
            } else {
                $FoundLabel.Text = 'Βρέθηκαν' + " $CsvCounter " + 'αρχεία CSV για σάρωση.'
            }
            $ParseLabel.Text = 'Γίνεται σάρωση...'
            $WaitLabel.Text = 'Παρακαλώ περιμένετε...'
        }
        
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
#>
function Get-ContactsTool
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Param1
    )
    Begin
    {
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = "Εργαλείο επαφών"
        $Form.Width = 800
        $Form.Height = 500
        $Form.MaximizeBox = $False
        $Form.StartPosition = 'CenterScreen'
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
        
        # Set the font of the text to be used within the form
        $Font = New-Object System.Drawing.Font("Calibri",16)
        $Form.Font = $Font

        $SearchPanel = New-Object System.Windows.Forms.TabPage
        $SearchPanel.TabIndex = 0
        $SearchPanel.Text = "Αναζήτηση"
        $SearchPanel.BackColor = [System.Drawing.Color]::WhiteSmoke

        $AddContactPanel = New-Object System.Windows.Forms.TabPage
        $AddContactPanel.TabIndex = 1
        $AddContactPanel.Text = "Προσθήκη νέας επαφής"
        $AddContactPanel.BackColor = [System.Drawing.Color]::WhiteSmoke

        $tab_control = new-object System.Windows.Forms.TabControl
        $tab_control.Controls.Add($SearchPanel)
        $tab_control.Controls.Add($AddContactPanel)
        $tab_control.Size = '792,468'
        $tab_control.TabIndex = 0
        $Form.Controls.Add($tab_control)
    
        $SearchTextField = New-Object System.Windows.Forms.TextBox
        $SearchTextField.Location = '20, 250'
        $SearchTextField.Size = '350, 25'
        $SearchTextField.BackColor = [System.Drawing.Color]::White
        $SearchPanel.controls.Add($SearchTextField)

        $SearchButton = New-Object System.Windows.Forms.Button
        $SearchButton.Location = '20, 300'
        $SearchButton.Size = '150,50'
        $SearchButton.Text = 'Αναζήτηση'
        $SearchButton.BackColor = [System.Drawing.Color]::RosyBrown
        $SearchPanel.controls.Add($SearchButton)       

        $FileFoundLabel = New-Object System.Windows.Forms.Label
        $FileFoundLabel.Location = '20, 25'
        $FileFoundLabel.Size = '350, 25'
        $SearchPanel.controls.Add($FileFoundLabel)
        
        $FilesFoundListBox = New-Object System.Windows.Forms.ListBox
        $FilesFoundListBox.Location = '25, 60'
        $FilesFoundListBox.Size = '250, 150'
        $SearchPanel.Controls.Add($FilesFoundListBox)
        
        #$FilesFoundListBox.Enabled = $false
        
        $ContactsFound = New-Object System.Windows.Forms.Label
        $ContactsFound.Location = '440, 250'
        $ContactsFound.Size = '250, 50'
        $SearchPanel.Controls.Add($ContactsFound)

        # check file exist link:
        # https://technet.microsoft.com/en-us/library/ff730955.aspx
        # FOR SCRIPT USE THIS 
        [switch]$CsvExists = Test-Path -Path $PSScriptRoot\* -Include *.csv       
        if (!$CsvExists){
            Write-Host "de vrethike arxeio csv"
            $FileFoundLabel.Text = 'Δε βρέθηκαν αρχεία CSV για σάρωση.'

        } else {
            # measure csv files found
            $CsvCounter = (Get-ChildItem -Path $PSScriptRoot\*.csv | Measure-Object ).Count
            if ($CsvCounter -eq 1){
                $FileFoundLabel.Text = 'Βρέθηκαν' + " $CsvCounter " + 'αρχείο CSV για σάρωση.'
            } else {
                $FileFoundLabel.Text = 'Βρέθηκαν' + " $CsvCounter " + 'αρχεία CSV για σάρωση.'
            }

            $filesList = New-Object System.Collections.ArrayList 
            foreach ($fn in (Get-ChildItem -Path $PSScriptRoot\*.csv)){
                $addition = $filesList.Add($fn.ToString())
                $filesFound = $fn.ToString().Split("\").Get($fn.ToString().Split("\").Count-1)
                $addition = $FilesFoundListBox.Items.Add($filesFound)
            }

            [System.Management.Automation.PSCustomObject]$contacts
            foreach ($filePath in $filesList){
                $contacts += Import-Csv $filePath
            }
        }

        

        # listener for the search button
        $SearchButton.Add_Click({
            cls
            $SearchQuery = "*" + $SearchTextField.Text + "*"
            if ((($contacts | where {$_ -like $SearchQuery}) -ne "") -and $SearchQuery -ne "**"){
                $ContactsFoundNumber = (($contacts | where {$_ -like $SearchQuery}) | Measure-Object).Count
                if ($ContactsFoundNumber -eq 1){
                    $ContactsFound.Text = 'Βρέθηκε' + " $ContactsFoundNumber " + ' επαφή.'
                } else {
                    $ContactsFound.Text = 'Βρέθηκαν' + " $ContactsFoundNumber " + ' επαφές.'
                }
                $contacts | where {$_ -like $SearchQuery} | Out-GridView                           
            } elseif ($SearchQuery -eq "**") {
                $ContactsFoundNumber = (($contacts | where {$_ -like $SearchQuery}) | Measure-Object).Count
                if ($ContactsFoundNumber -eq 1){
                    $ContactsFound.Text = 'Βρέθηκε' + " $ContactsFoundNumber " + ' επαφή.'
                } else {
                    $ContactsFound.Text = 'Βρέθηκαν' + " $ContactsFoundNumber " + ' επαφές.'
                }
                $contacts | where {$_ -like $SearchQuery} | Out-GridView
            }
            

        })




        
        
    }
    Process
    {
    }
    End
    {
        $dialogResult = $Form.ShowDialog()
    }
}

Get-ContactsTool