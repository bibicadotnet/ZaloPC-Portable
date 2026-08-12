@echo off
setlocal enabledelayedexpansion

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

$tempDir = Join-Path $currentDir ("ZaloUpdateTemp_" + [guid]::NewGuid().ToString("N").Substring(0, 8))

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

  Get-ChildItem $currentDir -Directory -Filter "ZaloUpdateTemp*" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-ItemSafe $_.FullName }

  Write-Host ""
  Write-Host "ZaloPC Portable Updater"
  Write-Host "========================"
  Write-Host ""

  $currentVersion = if (Test-Path $exePath) { (Get-Item $exePath).VersionInfo.ProductVersion } else { "Not installed" }

  $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "ZaloPC-Portable-Updater" }
  $tag = $release.tag_name
  $latestVersion = $tag -replace '^Zalo-', ''
  $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
  if (-not $asset) { throw "Could not find a .zip file in the latest release." }
  $downloadUrl = $asset.browser_download_url

  $currentShort = ($currentVersion -split '\.')[0..2] -join '.'

  Write-Host "Current version : $currentVersion" -ForegroundColor Yellow
  Write-Host "Latest version  : $latestVersion" -ForegroundColor Yellow
  Write-Host ""

  if ($currentVersion -eq "Not installed") {
    $promptMsg = "Do you want to install Zalo version $latestVersion? (y/N)"
  } elseif ($currentShort -eq $latestVersion) {
    $promptMsg = "Zalo is already at the latest version ($currentVersion). Do you want to reinstall? (y/N)"
  } else {
    $promptMsg = "Do you want to update Zalo from $currentVersion to $latestVersion? (y/N)"
  }

  $confirm = Read-Host $promptMsg
  if ($confirm -ne 'y' -and $confirm -ne 'Y') { exit }
  Write-Host ""

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

  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
  $zipFile = Join-Path $tempDir "update.zip"
  $extractDir = Join-Path $tempDir "extracted"

  Write-Host "Downloading: $downloadUrl"
  $webClient.DownloadFile($downloadUrl, $zipFile)
  Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

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