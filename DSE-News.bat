@echo off
setlocal
title DSE News
set "APP=%LOCALAPPDATA%\DSE-News"
set "ZIP=%TEMP%\dse-news.zip"
set "PYEXE="

rem ---- Check System PATH first ----
python -c "import sys" >nul 2>nul
if not errorlevel 1 set "PYEXE=python"
if defined PYEXE goto havepython

rem ---- Search for any installed Python version automatically (3.15, 3.16, 3.18, etc.) ----
for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python3*") do (
    if exist "%%D\python.exe" set "PYEXE=%%D\python.exe"
)
if defined PYEXE goto havepython

rem ---- Fallback: Download Python 3.15 if no Python exists at all ----
set "PYVER=3.15.0"
set "PYDIR=%LOCALAPPDATA%\Programs\Python\Python315"

echo Python is not installed. Downloading and installing Python %PYVER%...
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-WebRequest -UseBasicParsing 'https://www.python.org/ftp/python/%PYVER%/python-%PYVER%-amd64.exe' -OutFile '%TEMP%\python-installer.exe' } catch { exit 1 }"
if errorlevel 1 goto pyfail
"%TEMP%\python-installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_launcher=0
if not exist "%PYDIR%\python.exe" goto pyfail
set "PYEXE=%PYDIR%\python.exe"
echo Python installed.
goto havepython

:pyfail
echo.
echo Automatic Python install failed. Please install Python from
echo https://www.python.org/downloads/ ^(tick "Add python.exe to PATH"^), then run this file again.
pause
exit /b 1

:havepython
echo Using Python: %PYEXE%
echo Downloading the latest DSE News app...
powershell -NoProfile -Command "try { Invoke-WebRequest -UseBasicParsing 'https://codeload.github.com/Abidhr-01/dse-data-scrape/zip/refs/heads/main' -OutFile '%ZIP%'; if (Test-Path '%APP%\src') { Remove-Item -Recurse -Force '%APP%\src' }; if (Test-Path '%APP%\tmp') { Remove-Item -Recurse -Force '%APP%\tmp' }; Expand-Archive -Force '%ZIP%' '%APP%\tmp'; Move-Item '%APP%\tmp\dse-data-scrape-main' '%APP%\src'; Remove-Item -Recurse -Force '%APP%\tmp' } catch { exit 1 }"
if errorlevel 1 (
    if not exist "%APP%\src\app.py" (
        echo Download failed. Check your internet connection.
        pause
        exit /b 1
    )
    echo Could not update; using the previously downloaded version.
)

cd /d "%APP%\src"
if not exist "%APP%\.setup_done" (
    echo First-time setup: installing Playwright and Chromium ^(a few minutes^)...
    "%PYEXE%" -m pip install playwright || (pause & exit /b 1)
    "%PYEXE%" -m playwright install chromium || (pause & exit /b 1)
    echo done> "%APP%\.setup_done"
)

start "" http://127.0.0.1:8000
"%PYEXE%" app.py --output "%USERPROFILE%\Documents\dse_news"
pause
