param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseDir,

    [ValidateRange(1, 120)]
    [int]$TimeoutSeconds = 15
)

$ErrorActionPreference = 'Stop'
$releasePath = (Resolve-Path -LiteralPath $ReleaseDir).Path
$logPath = Join-Path $releasePath 'smoke-test.log'
$process = $null
$exitCode = 0

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

    try {
        Write-SmokeLog 'Recent Application Error events:'
        Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            Level = 2
            StartTime = (Get-Date).AddMinutes(-10)
        } -MaxEvents 10 -ErrorAction Stop |
            ForEach-Object { Write-SmokeLog "$($_.TimeCreated) $($_.ProviderName): $($_.Message)" }
    } catch {
        Write-SmokeLog "Application event log unavailable: $($_.Exception.Message)"
    }
}

try {
    Set-Content -LiteralPath $logPath -Value '' -Encoding UTF8
    $requiredFiles = @(
        'github_news.exe',
        'flutter_windows.dll',
        'data\app.so'
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

    $executable = Join-Path $releasePath 'github_news.exe'
    Write-SmokeLog "Starting $executable"
    $process = Start-Process `
        -FilePath $executable `
        -WorkingDirectory $releasePath `
        -WindowStyle Minimized `
        -PassThru

    $passed = $false
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 200
        $process.Refresh()
        if ($process.HasExited) {
            throw "Application exited before opening a window. Exit code: $($process.ExitCode)"
        }
        if ($process.MainWindowHandle -ne 0) {
            Write-SmokeLog "Smoke test passed. MainWindowHandle=$($process.MainWindowHandle)"
            $passed = $true
            break
        }
    } while ([DateTime]::UtcNow -lt $deadline)

    if (-not $passed) {
        throw "Application did not expose a main window within $TimeoutSeconds seconds."
    }
} catch {
    Write-SmokeLog "Smoke test failed: $($_.Exception.Message)"
    Write-FailureDiagnostics -FailedProcess $process
    $exitCode = 1
} finally {
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
