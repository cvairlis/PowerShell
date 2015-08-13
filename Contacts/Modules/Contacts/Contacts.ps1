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
function Get-ContactsTool
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
    )
    Begin
    {
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = "Εργαλείο επαφών"
        $Form.Width = 1100
        $Form.Height = 700
        $Form.MaximizeBox = $False
        $Form.StartPosition = 'CenterScreen'
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
        
        # Set the font of the text to be used within the form
        $Font = New-Object System.Drawing.Font("Calibri",16)
        $Form.Font = $Font

        $ContactsPanel = New-Object System.Windows.Forms.TabPage
        $ContactsPanel.TabIndex = 0
        $ContactsPanel.Text = 'Επαφές'
        $ContactsPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
        
        $SearchPanel = New-Object System.Windows.Forms.TabPage
        $SearchPanel.TabIndex = 1
        $SearchPanel.Text = "Αναζήτηση"
        $SearchPanel.BackColor = [System.Drawing.Color]::WhiteSmoke

        $AddContactPanel = New-Object System.Windows.Forms.TabPage
        $AddContactPanel.TabIndex = 2
        $AddContactPanel.Text = "Προσθήκη νέας επαφής"
        $AddContactPanel.BackColor = [System.Drawing.Color]::WhiteSmoke

        $tab_control = new-object System.Windows.Forms.TabControl
        $tab_control.Controls.Add($ContactsPanel)
        $tab_control.Controls.Add($SearchPanel)
        $tab_control.Controls.Add($AddContactPanel)
        $tab_control.Size = '1092,668'
        $tab_control.TabIndex = 0
        $Form.Controls.Add($tab_control)
    
        $ResetContactsPanelButton = New-Object System.Windows.Forms.Button
        $ResetContactsPanelButton.Location = '10, 15'
        $ResetContactsPanelButton.Size = '200, 50'
        $ResetContactsPanelButton.Text = 'Επαναφορά'
        $ContactsPanel.Controls.Add($ResetContactsPanelButton)

        $ContactsComboBox = New-Object System.Windows.Forms.ComboBox
        $ContactsComboBox.Size = '350,200'
        $ContactsComboBox.Location = '10,90'
        $ContactsComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        $ContactsPanel.Controls.Add($ContactsComboBox)
  
        $ContactSelected = New-Object System.Windows.Forms.TextBox
        $ContactSelected.Multiline = $true
        $ContactSelected.size = '650, 500'
        $ContactSelected.Location = '400, 90'
        $ContactSelected.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
        
        $ContactsPanel.Controls.Add($ContactSelected)  
        
  
        
        $SearchTextField = New-Object System.Windows.Forms.TextBox
        $SearchTextField.Location = '20, 350'
        $SearchTextField.Size = '350, 25'
        $SearchTextField.BackColor = [System.Drawing.Color]::White
        $SearchPanel.controls.Add($SearchTextField)

        $SearchButton = New-Object System.Windows.Forms.Button
        $SearchButton.Location = '20, 420'
        $SearchButton.Size = '200,80'
        $SearchButton.Text = 'Αναζήτηση'
        $SearchButton.BackColor = [System.Drawing.Color]::RosyBrown
        $SearchPanel.controls.Add($SearchButton)       

        $FileFoundLabel = New-Object System.Windows.Forms.Label
        $FileFoundLabel.Location = '20, 25'
        $FileFoundLabel.Size = '550, 25'
        $SearchPanel.controls.Add($FileFoundLabel)
        
        $FilesFoundListBox = New-Object System.Windows.Forms.ListBox
        $FilesFoundListBox.Location = '25, 100'
        $FilesFoundListBox.Size = '250, 150'
        $SearchPanel.Controls.Add($FilesFoundListBox)
        
        #$FilesFoundListBox.Enabled = $false
        
        $ContactsFound = New-Object System.Windows.Forms.Label
        $ContactsFound.Location = '440, 350'
        $ContactsFound.Size = '250, 50'
        $SearchPanel.Controls.Add($ContactsFound)

        # check file exist link:
        # https://technet.microsoft.com/en-us/library/ff730955.aspx
        # FOR SCRIPT USE THIS 
        [switch]$CsvExists = Test-Path -Path $PSScriptRoot\* -Include *.csv       
        if (!$CsvExists){            
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

        $array = new-object System.Collections.ArrayList
        $array.AddRange($contacts)
        
        $names = New-Object System.Collections.ArrayList
        foreach ($contact in $array){
            $addition = $names.Add($contact.Ονοματεπώνυμο)
        }

        $ContactsComboBox.DataSource = $names
        $ContactsComboBox.SelectedIndex = 0
        #$ContactsGrid.DataSource = $array

        # combo box event handler
        $ContactsComboBox.add_SelectedIndexChanged({
            foreach ($contact in $array){
                            
                if ($contact."Ονοματεπώνυμο" -eq $ContactsComboBox.Text){
                    $ContactSelected.Text = ($contact | Format-List | Out-String).TrimStart().TrimEnd()
                }       
            }
            #write-host $ContactsComboBox.Text
            
        })

        # listener for the search button
        $SearchButton.Add_Click({
            cls
            $SearchQuery = "*" + $SearchTextField.Text + "*"
            if ((($contacts | where {$_ -like $SearchQuery}) -ne "") -and $SearchQuery -ne "**"){
                $ContactsFoundNumber = (($contacts | where {$_ -like $SearchQuery}) | Measure-Object).Count
                if ($ContactsFoundNumber -eq 1){
                    $ContactsFound.Text = 'Βρέθηκε' + " $ContactsFoundNumber " + 'επαφή.'
                } else {
                    $ContactsFound.Text = 'Βρέθηκαν' + " $ContactsFoundNumber " + 'επαφές.'
                }
                $FoundContacts = new-object System.Collections.ArrayList
                $contacts | where {$_ -like $SearchQuery} | ForEach-Object { $FoundContacts.Add($_.Ονοματεπώνυμο)}
                
                $ContactsComboBox.DataSource = $FoundContacts                        


            } elseif ($SearchQuery -eq "**") {
                $ContactsFoundNumber = (($contacts | where {$_ -like $SearchQuery}) | Measure-Object).Count
                if ($ContactsFoundNumber -eq 1){
                    $ContactsFound.Text = 'Βρέθηκε' + " $ContactsFoundNumber " + 'επαφή.'
                } else {
                    $ContactsFound.Text = 'Βρέθηκαν' + " $ContactsFoundNumber " + 'επαφές.'
                }
                #$contacts | where {$_ -like $SearchQuery} | Out-GridView
                $ContactsGrid.DataSource = $array
            }
        })

        $ResetContactsPanelButton.Add_Click({
            $ContactsComboBox.DataSource = $names
            $ContactsComboBox.SelectedIndex = 0
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