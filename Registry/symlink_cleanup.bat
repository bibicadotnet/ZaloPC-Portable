@echo off
if exist "%APPDATA%\ZaloData" rmdir "%APPDATA%\ZaloData"
if exist "%LOCALAPPDATA%\ZaloPC" rmdir "%LOCALAPPDATA%\ZaloPC"
if exist "%USERPROFILE%\Documents\Zalo Received Files" rmdir "%USERPROFILE%\Documents\Zalo Received Files"

if exist "%APPDATA%\ZaloData_bak" rename "%APPDATA%\ZaloData_bak" "ZaloData"
if exist "%LOCALAPPDATA%\ZaloPC_bak" rename "%LOCALAPPDATA%\ZaloPC_bak" "ZaloPC"
if exist "%USERPROFILE%\Documents\Zalo Received Files_bak" rename "%USERPROFILE%\Documents\Zalo Received Files_bak" "Zalo Received Files"
