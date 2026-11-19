@echo off
rem Double-click: records the output of every demo into the backup folder.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0make-backup.ps1"
pause
