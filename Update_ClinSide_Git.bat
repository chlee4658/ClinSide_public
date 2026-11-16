@echo off
setlocal EnableExtensions
chcp 65001 >nul
title ClinSide Update
set "APP_DIR=%~dp0"

echo ClinSide will be updated from the latest Windows release.
echo Close ClinSide and stop its local server before continuing.
choice /C YN /M "Continue with update"
if errorlevel 2 goto :cancel

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update_ClinSide_Git.ps1"
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" goto :failed
echo.
echo Update complete. Start ClinSide-Windows.bat.
goto :end

:cancel
echo Update cancelled.
goto :end

:failed
echo.
echo Update failed. The pre-update backup, if created, remains available.
pause
exit /b 1

:end
pause
exit /b 0
