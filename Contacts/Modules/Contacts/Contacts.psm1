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
        $Form.Text = "Επαφές"
        $Form.Width = 700
        $Form.Height = 600
        $Form.MaximizeBox = $False
        $Form.StartPosition = 'CenterScreen'
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

        # Set the font of the text to be used within the form
        $Font = New-Object System.Drawing.Font("Calibri",12)
        $Form.Font = $Font

        $dialogResult = $Form.ShowDialog()

    }
    Process
    {
    }
    End
    {
    }
}