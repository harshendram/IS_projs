@echo off
rem Double-click: checks that gitleaks and git are installed.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp000-check-setup.ps1"
pause
