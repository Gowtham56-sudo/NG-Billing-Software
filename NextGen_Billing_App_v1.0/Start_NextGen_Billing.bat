@echo off
title NextGen Voice Billing Software Launcher
echo =====================================================
echo    Starting NextGen AI Voice Billing Software...
echo =====================================================
echo.

:: Detect Python environment (Standalone Portable Python first, then venv, then system)
set "PY_CMD="
if exist "%~dp0python_voice_server\python_runtime\python.exe" (
    set "PY_CMD=%~dp0python_voice_server\python_runtime\python.exe"
    echo [INFO] Using Bundled Standalone Portable Python AI Runtime.
) else if exist "%~dp0python_voice_server\venv\Scripts\python.exe" (
    set "PY_CMD=%~dp0python_voice_server\venv\Scripts\python.exe"
    echo [INFO] Using packaged Python venv environment.
) else (
    set "PY_CMD=python"
    echo [INFO] Using system Python.
)

:: Start Python Voice Server in background
echo [1/2] Launching Python Voice AI Engine...
if exist "%~dp0python_voice_server\server.py" (
    start /min "NextGen Voice Backend" cmd /c "cd /d "%~dp0python_voice_server" && "%PY_CMD%" server.py"
)

:: Small wait for WebSocket server to bind port 8765
timeout /t 3 /nobreak >nul

:: Launch Flutter Windows App
echo [2/2] Launching POS Billing Desktop Application...
if exist "%~dp0build\windows\x64\runner\Release\nextgen_billing_software.exe" (
    start "" "%~dp0build\windows\x64\runner\Release\nextgen_billing_software.exe"
) else if exist "%~dp0nextgen_billing_software.exe" (
    start "" "%~dp0nextgen_billing_software.exe"
) else (
    echo [ERROR] Could not find nextgen_billing_software.exe!
    pause
    exit /b 1
)

echo.
echo =====================================================
echo    NextGen Billing Software is ready and running!
echo =====================================================
