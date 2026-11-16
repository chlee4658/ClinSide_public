param([switch]$ValidatePathOnly)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($env:APP_DIR)) { throw 'APP_DIR is missing. Launch this script using the update BAT.' }
$app = [IO.Path]::GetFullPath($env:APP_DIR).TrimEnd('\')
if (-not (Test-Path -LiteralPath $app -PathType Container)) { throw ('ClinSide folder not found: ' + $app) }
if ($ValidatePathOnly) { Write-Host ('Valid ClinSide path: ' + $app); exit 0 }
$url = 'https://raw.githubusercontent.com/chlee4658/ClinSide_public/main/clinside.zip'
$temp = Join-Path $env:TEMP ('ClinSideUpdate-' + [guid]::NewGuid().ToString('N'))
$zip = Join-Path $temp 'release.zip'
$stage = Join-Path $temp 'stage'
$backup = $null
try {
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Invoke-WebRequest -Uri $url -OutFile $zip
    Expand-Archive -LiteralPath $zip -DestinationPath $stage -Force
    foreach ($required in @('ClinSide-Windows.bat','server.py','phrases.html')) {
        if (-not (Test-Path -LiteralPath (Join-Path $stage $required))) { throw ('Downloaded package is incomplete: ' + $required) }
    }
    $backupRoot = Join-Path (Split-Path -Parent $app) 'ClinSide_Backup'
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    $backup = Join-Path $backupRoot ('ClinSide-before-update-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6))
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    $excluded = @('data','backups','runtime','.git')
    Write-Host '[1/2] Backing up current code...'
    $copyArgs = @($app, $backup, '/E', '/R:1', '/W:1', '/XD') + @($excluded | ForEach-Object { Join-Path $app $_ }) + @('/XF','*.zip')
    & robocopy @copyArgs | Out-Null
    if ($LASTEXITCODE -ge 8) { throw 'Could not create the pre-update backup.' }
    Write-Host '[2/2] Updating public code...'
    $syncArgs = @($stage, $app, '/E', '/R:1', '/W:1', '/XD') + @($excluded | ForEach-Object { Join-Path $stage $_ }) + @('/XF','Update_ClinSide_Git.bat','Update_ClinSide_Git.ps1')
    & robocopy @syncArgs | Out-Null
    if ($LASTEXITCODE -ge 8) { throw 'File copy failed. Restore files from the backup.' }

    $backups = @(Get-ChildItem -LiteralPath $backupRoot -Directory | Where-Object {
        $_.Name -match '^ClinSide-before-(dev-)?update-\d{8}-\d{6}(-[0-9a-f]{6})?$'
    } | Sort-Object { if ($_.Name -match '(\d{8}-\d{6})') { $Matches[1] } else { '' } } -Descending)
    foreach ($old in ($backups | Select-Object -Skip 3)) {
        try { Remove-Item -LiteralPath $old.FullName -Recurse -Force -ErrorAction Stop }
        catch { Write-Warning ('Could not remove old backup: ' + $old.FullName) }
    }
    Write-Host 'Updated from ClinSide_public.'
    Write-Host ('Code backup: ' + $backup)
    Write-Host 'data, backups, runtime and updater files were preserved.'
} catch {
    Write-Host ('UPDATE FAILED: ' + $_.Exception.Message)
    if ($backup) { Write-Host ('Backup (if created): ' + $backup) }
    exit 1
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
