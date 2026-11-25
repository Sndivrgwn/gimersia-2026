Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" | Select-Object ProcessId, CommandLine | Format-List
