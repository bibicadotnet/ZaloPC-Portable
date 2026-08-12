@echo off
:: Clean up junctions
if exist "%APPDATA%\ZaloData" rmdir "%APPDATA%\ZaloData"
if exist "%LOCALAPPDATA%\ZaloPC" rmdir "%LOCALAPPDATA%\ZaloPC"
if exist "%USERPROFILE%\Documents\Zalo Received Files" rmdir "%USERPROFILE%\Documents\Zalo Received Files"
