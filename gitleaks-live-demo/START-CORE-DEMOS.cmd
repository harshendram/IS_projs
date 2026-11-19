@echo off
rem Double-click: opens only the core demos 1-4 (the 6-minute live part).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0open-terminals.ps1" -Demos 1,2,3,4
if errorlevel 1 pause
