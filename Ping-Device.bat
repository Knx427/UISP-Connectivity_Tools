@echo off
set /p ip=Enter IP address: 
set /p interval=Enter Interval: 
set /p set_timeout=Enter Timeout: 

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0wait-for-ip.ps1" -ip "%ip%" -interval %interval% -set_timeout %set_timeout%

pause
