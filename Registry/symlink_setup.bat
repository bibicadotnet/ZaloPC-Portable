@echo off
set "PORTABLE_ROOT=%~dp0.."

:: Create target directories if they don't exist in portable folder
if not exist "%PORTABLE_ROOT%\Data\Roaming\ZaloData" mkdir "%PORTABLE_ROOT%\Data\Roaming\ZaloData"
if not exist "%PORTABLE_ROOT%\Data\Local\ZaloPC" mkdir "%PORTABLE_ROOT%\Data\Local\ZaloPC"
if not exist "%PORTABLE_ROOT%\Data\Documents\Zalo Received Files" mkdir "%PORTABLE_ROOT%\Data\Documents\Zalo Received Files"

:: Create junctions
if not exist "%APPDATA%\ZaloData" mklink /j "%APPDATA%\ZaloData" "%PORTABLE_ROOT%\Data\Roaming\ZaloData"
if not exist "%LOCALAPPDATA%\ZaloPC" mklink /j "%LOCALAPPDATA%\ZaloPC" "%PORTABLE_ROOT%\Data\Local\ZaloPC"
if not exist "%USERPROFILE%\Documents\Zalo Received Files" mklink /j "%USERPROFILE%\Documents\Zalo Received Files" "%PORTABLE_ROOT%\Data\Documents\Zalo Received Files"
