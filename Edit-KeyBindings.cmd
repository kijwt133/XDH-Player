@echo off
setlocal
chcp 65001 >nul
if not exist "%~dp0runtime\user\input_config\default.ini.before-edit.bak" copy /b "%~dp0runtime\user\input_config\default.ini" "%~dp0runtime\user\input_config\default.ini.before-edit.bak" >nul
start "" notepad.exe "%~dp0runtime\user\input_config\default.ini"
start "" notepad.exe "%~dp0键位说明.txt"
endlocal
