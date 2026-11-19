@echo off
rem Double-click: deletes all demo workspaces in Documents\gitleaks-live.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0reset.ps1"
pause
