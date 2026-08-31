@echo off
title Package NextGen Billing Software for Distribution
echo =======================================================
echo   Packaging NextGen Billing Software for Testing...
echo =======================================================
echo.

set "DIST_DIR=%~dp0NextGen_Billing_App_v1.0"

if exist "%DIST_DIR%" (
    echo Cleaning previous package...
    rmdir /s /q "%DIST_DIR%"
)

mkdir "%DIST_DIR%"
mkdir "%DIST_DIR%\python_voice_server"

echo [1/4] Copying Flutter Release Binaries...
xcopy /E /I /Y "%~dp0build\windows\x64\runner\Release\*" "%DIST_DIR%\"

echo [2/4] Copying Python Voice AI Engine...
xcopy /E /I /Y "%~dp0python_voice_server\*" "%DIST_DIR%\python_voice_server\"

echo [3/4] Copying Launcher and Scripts...
copy /Y "%~dp0Start_NextGen_Billing.bat" "%DIST_DIR%\"

:: Create Easy Setup Script for Teammates
(
echo @echo off
echo title NextGen Billing - One-Time Dependency Setup
echo =======================================================
echo   Installing Python Dependencies for Voice Engine...
echo =======================================================
echo.
echo Checking Python...
python --version
if %%errorlevel%% neq 0 (
    echo [ERROR] Python is not installed. Please install Python 3.10+ and check "Add Python to PATH".
    pause
    exit /b 1
)
echo.
echo Installing required AI libraries...
cd /d "%%~dp0python_voice_server"
pip install -r requirements.txt
echo.
echo =======================================================
echo   Setup Complete! Now you can run Start_NextGen_Billing.bat
echo =======================================================
pause
) > "%DIST_DIR%\1_Install_Dependencies.bat"

:: Create Testing Guide Readme
(
echo ============================================================
echo      NEXTGEN AI VOICE BILLING SOFTWARE - TESTING GUIDE
echo ============================================================
echo.
echo [HOW TO RUN THE APPLICATION ON ANY WINDOWS PC]
echo.
echo STEP 1 (One-Time Setup):
echo   - Make sure Python (version 3.10 or higher) is installed on the PC.
echo   - Double-click "1_Install_Dependencies.bat" to install voice AI libraries.
echo.
echo STEP 2 (Launch Application):
echo   - Double-click "Start_NextGen_Billing.bat".
echo   - This will automatically start the Python Voice Backend and open the POS Billing GUI.
echo.
echo STEP 3 (Testing Voice Billing):
echo   - Plug in a microphone / headset.
echo   - Open the Cashier Panel in the app.
echo   - Say Tamil / English voice commands, for example:
echo       * "Rendu aavin milk podu"
echo       * "Add 1 sun pure oil"
echo       * "Remove aavin milk"
echo       * "10 percent discount kudu"
echo       * "Print bill" or "Cash payment"
echo.
echo [ADMIN PANEL CREDENTIALS]
echo   - Role: Admin
echo   - Default Login: admin / admin123 (or demo accounts)
echo.
) > "%DIST_DIR%\README_TESTING.txt"

echo [4/4] Package Created Successfully at:
echo %DIST_DIR%
echo.
echo You can now ZIP the folder "%DIST_DIR%" and send it to your teammates!
pause
