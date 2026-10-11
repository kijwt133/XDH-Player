@echo off
setlocal
chcp 65001 >nul
set "saveRoot=%~dp0runtime\user\home\1000\savedata"
if not exist "%saveRoot%" mkdir "%saveRoot%"
start "" explorer.exe "%saveRoot%"
start "" notepad.exe "%~dp0存档说明.txt"
endlocal
