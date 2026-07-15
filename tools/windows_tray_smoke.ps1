param(
  [string]$ReleaseDir = "build/windows/x64/runner/Release",
  [int]$StartupTimeoutSeconds = 15
)

$ErrorActionPreference = "Stop"
$resolvedRelease = (Resolve-Path -LiteralPath $ReleaseDir).Path
$exe = Join-Path $resolvedRelease "github_news.exe"
if (-not (Test-Path -LiteralPath $exe)) {
  throw "Release executable not found: $exe"
}

$process = Start-Process -FilePath $exe -WorkingDirectory $resolvedRelease -PassThru
try {
  $deadline = [DateTime]::UtcNow.AddSeconds($StartupTimeoutSeconds)
  do {
    Start-Sleep -Milliseconds 250
    $process.Refresh()
    if ($process.HasExited) {
      throw "Application exited before its main window became ready. ExitCode=$($process.ExitCode)"
    }
  } while ($process.MainWindowHandle -eq 0 -and [DateTime]::UtcNow -lt $deadline)

  if ($process.MainWindowHandle -eq 0) {
    throw "Application did not expose a main window within $StartupTimeoutSeconds seconds"
  }
  if (-not $process.CloseMainWindow()) {
    throw "Failed to send the close request to the main window"
  }
  Start-Sleep -Seconds 2
  $process.Refresh()
  if ($process.HasExited) {
    throw "Application exited after window close; tray keep-alive is not active"
  }
  Write-Output "Tray smoke test passed. ProcessId=$($process.Id) remained alive after window close."
}
finally {
  if (-not $process.HasExited) {
    Stop-Process -Id $process.Id -Force
  }
}
