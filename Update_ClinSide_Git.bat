@echo off
setlocal
chcp 65001 >nul
title ClinSide Update
set "APP_DIR=%~dp0"
set "UPDATE_URL=https://raw.githubusercontent.com/chlee4658/ClinSide_public/main/clinside.zip"

echo ClinSide will be updated from the latest Windows release.
echo Close ClinSide and stop its local server before continuing.
choice /C YN /M "Continue with update"
if errorlevel 2 goto :cancel

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $app=[IO.Path]::GetFullPath('%APP_DIR%'); $url='%UPDATE_URL%'; $temp=Join-Path $env:TEMP ('ClinSideUpdate-' + [guid]::NewGuid().ToString('N')); $zip=Join-Path $temp 'release.zip'; $stage=Join-Path $temp 'stage'; try { New-Item -ItemType Directory -Force -Path $stage | Out-Null; Invoke-WebRequest -Uri $url -OutFile $zip; Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force; if (-not (Test-Path (Join-Path $stage 'ClinSide-Windows.bat'))) { throw 'Downloaded package is incomplete.' }; $excluded=@('data','backups','runtime','.git'); $backupRoot=Join-Path (Split-Path $app.TrimEnd('\') -Parent) 'ClinSide_Backup'; New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null; $backup=Join-Path $backupRoot ('ClinSide-before-update-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6)); New-Item -ItemType Directory -Force -Path $backup | Out-Null; $copyArgs=@($app,$backup,'/E','/R:1','/W:1','/XD') + @($excluded | ForEach-Object { Join-Path $app $_ }) + @('/XF','Update_ClinSide_Git.bat'); & robocopy @copyArgs; if ($LASTEXITCODE -ge 8) { throw 'Could not create the pre-update backup.' }; $syncArgs=@($stage,$app,'/E','/R:1','/W:1','/XD') + @($excluded | ForEach-Object { Join-Path $stage $_ }) + @('/XF','Update_ClinSide_Git.bat'); & robocopy @syncArgs; if ($LASTEXITCODE -ge 8) { throw 'File copy failed. Restore files from the backup if needed.' }; $completed=@(Get-ChildItem -LiteralPath $backupRoot -Directory | Where-Object { $_.Name -match '^ClinSide-before-(dev-)?update-\\d{8}-\\d{6}(-[0-9a-f]{6})? Write-Host ('Backup: ' + $backup) } catch { Write-Host ('Update failed: ' + $_.Exception.Message); exit 1 } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }"
if errorlevel 1 goto :failed
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
 } | Sort-Object CreationTimeUtc -Descending); if($completed.Count -gt 3){foreach($older in ($completed | Select-Object -Skip 3)){try{Remove-Item -LiteralPath $older.FullName -Recurse -Force -ErrorAction Stop; Write-Host ('Removed old code backup: '+$older.Name)}catch{Write-Warning ('Could not remove old backup: '+$older.FullName+' - '+$_.Exception.Message)}}}; Write-Host 'Updated from ClinSide_public.'; Write-Host ('Backup: ' + $backup) } catch { Write-Host ('Update failed: ' + $_.Exception.Message); exit 1 } finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }"
if errorlevel 1 goto :failed
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
