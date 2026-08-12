@echo off
set "PORTABLE_ROOT=%~dp0.."

if not exist "%PORTABLE_ROOT%\Data\Roaming\ZaloData" mkdir "%PORTABLE_ROOT%\Data\Roaming\ZaloData"
if not exist "%PORTABLE_ROOT%\Data\Local\ZaloPC" mkdir "%PORTABLE_ROOT%\Data\Local\ZaloPC"
if not exist "%PORTABLE_ROOT%\Data\Documents\Zalo Received Files" mkdir "%PORTABLE_ROOT%\Data\Documents\Zalo Received Files"

dir /al "%APPDATA%" 2>nul | findstr /c:"ZaloData" >nul
if %errorlevel% equ 0 (
    rmdir "%APPDATA%\ZaloData"
) else (
    if exist "%APPDATA%\ZaloData" (
        if exist "%APPDATA%\ZaloData_bak" rmdir /s /q "%APPDATA%\ZaloData_bak"
        rename "%APPDATA%\ZaloData" "ZaloData_bak"
    )
)
mklink /j "%APPDATA%\ZaloData" "%PORTABLE_ROOT%\Data\Roaming\ZaloData"

dir /al "%LOCALAPPDATA%" 2>nul | findstr /c:"ZaloPC" >nul
if %errorlevel% equ 0 (
    rmdir "%LOCALAPPDATA%\ZaloPC"
) else (
    if exist "%LOCALAPPDATA%\ZaloPC" (
        if exist "%LOCALAPPDATA%\ZaloPC_bak" rmdir /s /q "%LOCALAPPDATA%\ZaloPC_bak"
        rename "%LOCALAPPDATA%\ZaloPC" "ZaloPC_bak"
    )
)
mklink /j "%LOCALAPPDATA%\ZaloPC" "%PORTABLE_ROOT%\Data\Local\ZaloPC"

dir /al "%USERPROFILE%\Documents" 2>nul | findstr /c:"Zalo Received Files" >nul
if %errorlevel% equ 0 (
    rmdir "%USERPROFILE%\Documents\Zalo Received Files"
) else (
    if exist "%USERPROFILE%\Documents\Zalo Received Files" (
        if exist "%USERPROFILE%\Documents\Zalo Received Files_bak" rmdir /s /q "%USERPROFILE%\Documents\Zalo Received Files_bak"
        rename "%USERPROFILE%\Documents\Zalo Received Files" "Zalo Received Files_bak"
    )
)
mklink /j "%USERPROFILE%\Documents\Zalo Received Files" "%PORTABLE_ROOT%\Data\Documents\Zalo Received Files"
