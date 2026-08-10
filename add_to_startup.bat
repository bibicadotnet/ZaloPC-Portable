@echo off
set "STARTUP_FILE=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Zalo.bat"

echo Adding Zalo to Startup...

echo @echo off> "%STARTUP_FILE%"
echo start "" "%~dp0Zalo.exe">> "%STARTUP_FILE%"

if exist "%STARTUP_FILE%" (
    echo.
    echo SUCCESS: Zalo has been added to Startup.
    echo Startup file located at: "%STARTUP_FILE%"
) else (
    echo.
    echo ERROR: Failed to create file in Startup. Check permissions or path.
)

echo.
pause