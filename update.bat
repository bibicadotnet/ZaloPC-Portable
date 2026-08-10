@echo off
setlocal enabledelayedexpansion

:: Re-launch elevated if not already running as Administrator.
:: taskkill needs this to reliably close all Zalo child processes.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -WorkingDirectory '%~dp0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$lines = Get-Content -LiteralPath '%~f0'; $idx = ($lines | Select-String -Pattern '^::PS_PAYLOAD::\s*$').LineNumber | Select-Object -Last 1; $c = ($lines[$idx..($lines.Count-1)]) -join [Environment]::NewLine; $tmp = Join-Path $env:TEMP ('zalo_update_payload_' + [guid]::NewGuid().ToString('N') + '.ps1'); Set-Content -LiteralPath $tmp -Value $c -Encoding UTF8; try { & $tmp '%~dp0' } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }"

if errorlevel 1 (
    echo.
    echo update.bat exited with an error. See the output above.
    pause
)

exit /b

::PS_PAYLOAD::
param([string]$currentDir)
$ErrorActionPreference = "Stop"

$repo    = "bibicadotnet/ZaloPC-Portable"
$appDir  = Join-Path $currentDir "App"
$exePath = Join-Path $appDir "Zalo.exe"
$apiUrl  = "https://api.github.com/repos/$repo/releases/latest"

# Unique folder name per run, so a locked leftover from a previous failed
# run never collides with (and blocks) the current one.
$tempDir = Join-Path $currentDir ("ZaloUpdateTemp_" + [guid]::NewGuid().ToString("N").Substring(0, 8))

# Removes a folder, retrying a few times in case a file inside is briefly
# locked (e.g. antivirus scanning freshly extracted .dll files). Never
# throws - worst case it just warns and leaves the folder behind.
function Remove-ItemSafe {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return }
  for ($i = 0; $i -lt 5; $i++) {
    try {
      Remove-Item $Path -Recurse -Force -ErrorAction Stop
      return
    } catch {
      Start-Sleep -Milliseconds 800
    }
  }
  Write-Host "Warning: could not fully remove '$Path' (a file inside is locked). You can delete it manually later." -ForegroundColor Yellow
}

try {
  $webClient = New-Object System.Net.WebClient
  $webClient.Headers.Add("User-Agent", "ZaloPC-Portable-Updater")

  # Clean up any leftover temp folders from previous runs (non-fatal if locked)
  Get-ChildItem $currentDir -Directory -Filter "ZaloUpdateTemp*" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-ItemSafe $_.FullName }

  Write-Host ""
  Write-Host "ZaloPC Portable Updater"
  Write-Host "========================"
  Write-Host ""

  # 1. Current version - read directly from App\Zalo.exe file metadata
  $currentVersion = if (Test-Path $exePath) { (Get-Item $exePath).VersionInfo.ProductVersion } else { "Not installed" }

  # 2. Latest version from GitHub Releases
  $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "ZaloPC-Portable-Updater" }
  $tag = $release.tag_name                     # e.g. Zalo-26.8.10
  $latestVersion = $tag -replace '^Zalo-', ''   # e.g. 26.8.10
  $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
  if (-not $asset) { throw "Could not find a .zip file in the latest release." }
  $downloadUrl = $asset.browser_download_url

  # App\Zalo.exe has 4 parts (26.8.10.2711), release tag has 3 parts (26.8.10) -> compare first 3 parts
  $currentShort = ($currentVersion -split '\.')[0..2] -join '.'

  Write-Host "Current version : $currentVersion" -ForegroundColor Yellow
  Write-Host "Latest version  : $latestVersion" -ForegroundColor Yellow
  Write-Host ""

  $confirm = Read-Host "Do you want to overwrite Zalo with version $latestVersion? (y/N)"
  if ($confirm -ne 'y' -and $confirm -ne 'Y') { exit }
  Write-Host ""

  # 3. Close Zalo if it's running, before overwriting files
  #    Using taskkill /T instead of Stop-Process so child processes
  #    (renderer/GPU/crash-handler) are killed too, not just the main one.
  # taskkill writes to stderr when it can't terminate a process (e.g. one
  # that already exited on its own). On PowerShell 7.3+, stderr output from
  # a native command is treated as a terminating error under
  # $ErrorActionPreference = "Stop", which would abort the whole script here.
  # Temporarily relax it just for this call so we can rely on the
  # Get-Process check below instead of taskkill's own exit status.
  function Kill-Zalo {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    taskkill /F /IM Zalo.exe /T 2>$null | Out-Null
    $ErrorActionPreference = $prevEAP
  }

  $running = Get-Process -Name "Zalo" -ErrorAction SilentlyContinue
  if ($running) {
    Write-Host "Closing Zalo..."
    Kill-Zalo

    # Verify it's actually gone; retry a few times since some child
    # processes can take a moment to release their file handles.
    $retries = 0
    while ((Get-Process -Name "Zalo" -ErrorAction SilentlyContinue) -and $retries -lt 5) {
      Start-Sleep -Seconds 1
      Kill-Zalo
      $retries++
    }

    if (Get-Process -Name "Zalo" -ErrorAction SilentlyContinue) {
      Write-Host "Could not close Zalo. Please close it manually and run this again." -ForegroundColor Red
      Write-Host ""
      Read-Host "Press Enter to exit"
      exit
    }
    Start-Sleep -Seconds 1
  }

  # 4. Download and extract the update
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
  $zipFile = Join-Path $tempDir "update.zip"
  $extractDir = Join-Path $tempDir "extracted"

  Write-Host "Downloading: $downloadUrl"
  $webClient.DownloadFile($downloadUrl, $zipFile)
  Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

  # Zalo.exe may sit right at the zip root, or inside a single wrapper folder
  $topDirs = Get-ChildItem $extractDir -Directory
  $topFiles = Get-ChildItem $extractDir -File
  if ($topDirs.Count -eq 1 -and $topFiles.Count -eq 0) {
    $extractedRoot = $topDirs[0].FullName
  } else {
    $extractedRoot = $extractDir
  }

  if (-not (Test-Path (Join-Path $extractedRoot "Zalo.exe"))) {
    throw "Could not find Zalo.exe in the downloaded package."
  }

  # 5. Overwrite the App folder
  if (-not (Test-Path $appDir)) { New-Item -ItemType Directory -Path $appDir -Force | Out-Null }

  robocopy $extractedRoot $appDir /MIR /R:2 /W:2 /NFL /NDL | Out-Null

  Remove-ItemSafe $tempDir

  $newVersion = if (Test-Path $exePath) { (Get-Item $exePath).VersionInfo.ProductVersion } else { "Unknown" }
  Write-Host ""
  if ((($newVersion -split '\.')[0..2] -join '.') -eq $latestVersion) {
    Write-Host "Update complete! Version: $newVersion" -ForegroundColor Green
  } else {
    Write-Host "Something may have gone wrong. Expected: $latestVersion, Actual: $newVersion" -ForegroundColor Yellow
  }

} catch {
  Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"