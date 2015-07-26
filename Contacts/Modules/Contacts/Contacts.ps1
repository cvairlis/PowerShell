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
    [OutputType([int])]
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
        $FoundLabel.Location = '20, 20'
        $FoundLabel.Size = '350, 30'
        $FoundLabel.Text = 'Γίνεται σάρωση αρχείων CSV...'
        $Form.Controls.Add($FoundLabel)

        $ParseLabel = New-Object System.Windows.Forms.Label
        $ParseLabel.Location = '20, 60'
        $ParseLabel.Size = '300, 30'
        $Form.Controls.Add($ParseLabel)

        $WaitLabel = New-Object System.Windows.Forms.Label
        $WaitLabel.Location = '20, 100'
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
                $FoundLabel.Text = 'Βρέθηκαν' + " $CsvCounter " + ' αρχείο CSV για σάρωση.'
            } else {
                $FoundLabel.Text = 'Βρέθηκαν' + " $CsvCounter " + ' αρχεία CSV για σάρωση.'
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

Get-Contacts
