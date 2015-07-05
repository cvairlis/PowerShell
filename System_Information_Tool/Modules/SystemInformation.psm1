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
        $Form.Text = "System Information"
        $Form.Width = 1200
        $Form.Height = 700
        $Form.MaximizeBox = $False
        $Form.StartPosition = 'CenterScreen'
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
        $Form.BackColor = [System.Drawing.Color]::CornflowerBlue
        
        # Set the font of the text to be used within the form
        $Font = New-Object System.Drawing.Font("Calibri",13)
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


Export-ModuleMember -Function Get-SystemInformation