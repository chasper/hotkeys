$Monitors = Get-WmiObject WmiMonitorID -Namespace root\wmi
$LogFile = "./monitors.txt"

# "Manufacturer,Name,Serial" | Out-File $LogFile

ForEach ($Monitor in $Monitors)
{
    # $Manufacturer = ($Monitor.ManufacturerName|where {$_ -ne 0}|ForEach{[char]$_}) -join ""
    $Name = ($Monitor.UserFriendlyName  |where {$_ -ne 0}| ForEach{[char]$_}) -join ""
    # $Serial = ($Monitor.SerialNumberID  |where {$_ -ne 0}| ForEach{[char]$_}) -join ""

    # "$Manufacturer,$Name,$Serial" | Out-File $LogFile -append
    $Name | Out-File $LogFile
}