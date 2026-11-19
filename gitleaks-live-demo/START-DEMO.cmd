@echo off
rem Double-click: opens demos 1-8, one Windows Terminal tab each.
rem From a terminal you can also pick demos:  START-DEMO.cmd 1,2,3,4
if "%~1"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0open-terminals.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0open-terminals.ps1" -Demos %*
)
if errorlevel 1 pause
