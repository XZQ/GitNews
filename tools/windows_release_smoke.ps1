param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseDir,

    [ValidateRange(1, 120)]
    [int]$TimeoutSeconds = 15,

    [switch]$ArtifactsOnly
)

$ErrorActionPreference = 'Stop'
$releasePath = (Resolve-Path -LiteralPath $ReleaseDir).Path
$logPath = Join-Path $releasePath 'smoke-test.log'
$process = $null
$exitCode = 0
$reportPath = Join-Path $releasePath ("startup-probe-{0}.json" -f [guid]::NewGuid().ToString('N'))
$previousReportPath = $env:GITHUB_NEWS_STARTUP_REPORT

function Write-SmokeLog {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] $Message"
    Write-Host $line
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

function Write-FailureDiagnostics {
    param([System.Diagnostics.Process]$FailedProcess)

    if ($null -ne $FailedProcess) {
        $FailedProcess.Refresh()
        if ($FailedProcess.HasExited) {
            Write-SmokeLog "Process exited with code $($FailedProcess.ExitCode)."
        } else {
            Write-SmokeLog 'Process was still running without a visible main window.'
        }
    }

    Write-SmokeLog 'Release directory contents:'
    Get-ChildItem -LiteralPath $releasePath -Recurse -Force |
        ForEach-Object { Write-SmokeLog $_.FullName }

    # Do not collect other applications' event logs or unsanitized exceptions.
}

try {
    Set-Content -LiteralPath $logPath -Value '' -Encoding UTF8
    $requiredFiles = @(
        'github_news.exe',
        'flutter_windows.dll',
        'data\app.so',
        'sqlite3.dll',
        'data\flutter_assets\NativeAssetsManifest.json'
    )
    $requiredDirectories = @('data\flutter_assets')

    foreach ($relativePath in $requiredFiles) {
        $path = Join-Path $releasePath $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required release file is missing: $relativePath"
        }
    }
    foreach ($relativePath in $requiredDirectories) {
        $path = Join-Path $releasePath $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            throw "Required release directory is missing: $relativePath"
        }
    }

    $manifest = Get-Content -LiteralPath (Join-Path $releasePath 'data\flutter_assets\NativeAssetsManifest.json') -Raw | ConvertFrom-Json
    $sqliteAsset = $manifest.'native-assets'.windows_x64.'package:sqlite3/src/ffi/libsqlite3.g.dart'
    if ($null -eq $sqliteAsset -or $sqliteAsset.Count -ne 2 -or $sqliteAsset[1] -ne 'sqlite3.dll') {
        throw 'SQLite native asset binding is missing or not portable. Regenerate the stale Flutter build cache and rebuild Release.'
    }
    if ($ArtifactsOnly) {
        Write-SmokeLog 'Release artifact bindings verified; application startup was not tested.'
        return
    }

    $executable = Join-Path $releasePath 'github_news.exe'
    $env:GITHUB_NEWS_STARTUP_REPORT = $reportPath
    Write-SmokeLog "Starting $executable"
    $process = Start-Process `
        -FilePath $executable `
        -WorkingDirectory $releasePath `
        -WindowStyle Hidden `
        -PassThru

    $passed = $false
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 200
        $process.Refresh()
        if ($process.HasExited) {
            throw "Application exited before opening a window. Exit code: $($process.ExitCode)"
        }
        $startup = $null
        if (Test-Path -LiteralPath $reportPath -PathType Leaf) {
            try {
                $startup = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
            } catch {
                # The writer may still be flushing; check again on the next poll.
            }
        }
        if ($null -ne $startup -and $startup.pid -eq $process.Id -and $startup.status -eq 'failed') {
            throw "Application initialization failed: $($startup.failureCode)"
        }
        if ($process.MainWindowHandle -ne 0 -and $null -ne $startup -and $startup.pid -eq $process.Id -and $startup.status -eq 'ready') {
            Write-SmokeLog "Smoke test passed. Storage readable, app frame ready. MainWindowHandle=$($process.MainWindowHandle)"
            $passed = $true
            break
        }
    } while ([DateTime]::UtcNow -lt $deadline)

    if (-not $passed) {
        throw "Application did not report storage and app-frame readiness within $TimeoutSeconds seconds."
    }
} catch {
    Write-SmokeLog "Smoke test failed: $($_.Exception.Message)"
    Write-FailureDiagnostics -FailedProcess $process
    $exitCode = 1
} finally {
    $env:GITHUB_NEWS_STARTUP_REPORT = $previousReportPath
    if ($null -ne $process) {
        $process.Refresh()
        if (-not $process.HasExited) {
            $null = $process.CloseMainWindow()
            if (-not $process.WaitForExit(3000)) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
        }
        $process.Dispose()
    }
}

exit $exitCode
