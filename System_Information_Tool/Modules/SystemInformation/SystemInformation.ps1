Write-Host "`nSystem Information Summary`n"
[string]$OS = (Get-WmiObject -Class Win32_OperatingSystem).Caption
$OS += " " + (Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture


Write-Host "Operating System: $OS"

[string]$CPU = (Get-WmiObject -Class Win32_Processor).Name
#$CPU +=

Write-Host "CPU: $CPU"

[System.UInt64]$Memory = (Get-WMIObject -class Win32_PhysicalMemory).Capacity
[string]$MemoryToString = ([math]::Round($Memory/1GB,2)).ToString()
$MemoryToString += " GB"

Write-Host "Memory: $MemoryToString"