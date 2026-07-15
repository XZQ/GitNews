# Setup Android env vars (user-level, idempotent). ASCII only to avoid
# Windows PowerShell 5.1 GBK/UTF-8 encoding issues.
$sdk = 'C:\Users\XZQ\AppData\Local\Android\Sdk'
$pt = Join-Path $sdk 'platform-tools'

if (-not (Test-Path (Join-Path $pt 'adb.exe'))) {
  Write-Host "adb.exe not found under $pt - check SDK path." -ForegroundColor Red
  exit 1
}

[Environment]::SetEnvironmentVariable('ANDROID_HOME', $sdk, 'User')
Write-Host "ANDROID_HOME = $sdk"

$p = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($null -eq $p) { $p = '' }
if ($p -notlike "*$pt*") {
  [Environment]::SetEnvironmentVariable('Path', ($p.TrimEnd(';') + ';' + $pt).TrimStart(';'), 'User')
  Write-Host "User PATH appended: $pt" -ForegroundColor Green
} else {
  Write-Host 'User PATH already contains platform-tools, skipped.'
}

Write-Host ''
Write-Host 'Done. Open a NEW terminal window, then run: adb --version' -ForegroundColor Green
