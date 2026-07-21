[CmdletBinding()]
param(
  [string]$Suite = 'quick',
  [string]$Manifest,
  [string]$ArtifactsRoot,
  [switch]$List,
  [switch]$Doctor,
  [switch]$DryRun,
  [switch]$KeepGoing,
  [switch]$VerboseSteps,
  [ValidateSet('Text', 'Json')]
  [string]$OutputFormat = 'Text',
  [string]$InternalStepFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-InternalHarnessStep {
  param([Parameter(Mandatory = $true)][string]$InputFile)

  try {
    $payload = Get-Content -LiteralPath $InputFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Set-Location -LiteralPath ([string]$payload.workingDirectory)
    $arguments = @($payload.arguments | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0

    if ([string]$payload.kind -eq 'process') {
      & ([string]$payload.command) @arguments
    } elseif ([string]$payload.kind -eq 'powershell') {
      & ([string]$payload.script) @arguments
    } else {
      throw "Unsupported internal step kind: $($payload.kind)"
    }

    $succeeded = $?
    $exitCode = [int]$global:LASTEXITCODE
    if (-not $succeeded -and $exitCode -eq 0) {
      $exitCode = 1
    }
    exit $exitCode
  } catch {
    Write-Error $_
    exit 1
  }
}

if (-not [string]::IsNullOrWhiteSpace($InternalStepFile)) {
  Invoke-InternalHarnessStep -InputFile $InternalStepFile
}

function Write-HarnessMessage {
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [ConsoleColor]$Color = [ConsoleColor]::Gray
  )

  if ($OutputFormat -eq 'Text') {
    Write-Host $Message -ForegroundColor $Color
  }
}

function Get-NamedValue {
  param(
    [Parameter(Mandatory = $true)][object]$Container,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$ContainerName
  )

  $property = $Container.PSObject.Properties[$Name]
  if ($null -eq $property) {
    throw "Unknown $ContainerName '$Name'."
  }
  return $property.Value
}

function Get-CurrentPlatform {
  if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    return 'windows'
  }

  $kernel = (& uname -s 2>$null)
  if ($kernel -eq 'Darwin') {
    return 'macos'
  }
  return 'linux'
}

function Assert-AllowedPlatform {
  param(
    [object]$Item,
    [Parameter(Mandatory = $true)][string]$ItemName,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Platform
  )

  $platformProperty = $Item.PSObject.Properties['platforms']
  if ($null -eq $platformProperty) {
    return
  }

  $allowed = @($platformProperty.Value | ForEach-Object { [string]$_ })
  if ($allowed.Count -eq 0) {
    throw "$ItemName declares an empty platforms list."
  }
  if ([string]::IsNullOrWhiteSpace($Platform)) {
    return
  }
  if ($allowed -notcontains $Platform) {
    throw "$ItemName requires platform [$($allowed -join ', ')], current platform is '$Platform'."
  }
}

function Add-SuiteSteps {
  param(
    [Parameter(Mandatory = $true)][string]$SuiteName,
    [Parameter(Mandatory = $true)][object]$Suites,
    [Parameter(Mandatory = $true)][object]$Steps,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Stack,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.HashSet[string]]$SeenSteps,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Result,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Platform
  )

  if ($Stack.Contains($SuiteName)) {
    $cycle = (@($Stack) + $SuiteName) -join ' -> '
    throw "Harness suite include cycle detected: $cycle"
  }

  $suiteObject = Get-NamedValue -Container $Suites -Name $SuiteName -ContainerName 'suite'
  Assert-AllowedPlatform -Item $suiteObject -ItemName "Suite '$SuiteName'" -Platform $Platform
  $Stack.Add($SuiteName)

  $includeProperty = $suiteObject.PSObject.Properties['includes']
  if ($null -ne $includeProperty) {
    foreach ($includedSuite in @($includeProperty.Value)) {
      Add-SuiteSteps -SuiteName ([string]$includedSuite) -Suites $Suites -Steps $Steps -Stack $Stack -SeenSteps $SeenSteps -Result $Result -Platform $Platform
    }
  }

  $stepProperty = $suiteObject.PSObject.Properties['steps']
  if ($null -eq $stepProperty) {
    throw "Suite '$SuiteName' must declare a steps array."
  }
  foreach ($stepIdValue in @($stepProperty.Value)) {
    $stepId = [string]$stepIdValue
    $stepObject = Get-NamedValue -Container $Steps -Name $stepId -ContainerName 'step'
    Assert-AllowedPlatform -Item $stepObject -ItemName "Step '$stepId'" -Platform $Platform
    if ($SeenSteps.Add($stepId)) {
      $Result.Add($stepId)
    }
  }

  $Stack.RemoveAt($Stack.Count - 1)
}

function Get-ExpandedStepIds {
  param(
    [Parameter(Mandatory = $true)][string]$SuiteName,
    [Parameter(Mandatory = $true)][object]$Suites,
    [Parameter(Mandatory = $true)][object]$Steps,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Platform
  )

  $stack = [System.Collections.Generic.List[string]]::new()
  $seenSteps = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $result = [System.Collections.Generic.List[string]]::new()
  Add-SuiteSteps -SuiteName $SuiteName -Suites $Suites -Steps $Steps -Stack $stack -SeenSteps $seenSteps -Result $result -Platform $Platform
  return @($result)
}

function Assert-HarnessManifest {
  param(
    [Parameter(Mandatory = $true)][object]$ManifestObject,
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][string]$Platform
  )

  if ([int]$ManifestObject.schemaVersion -ne 1) {
    throw "Unsupported harness schemaVersion '$($ManifestObject.schemaVersion)'. Expected 1."
  }
  if ($null -eq $ManifestObject.PSObject.Properties['suites'] -or $null -eq $ManifestObject.PSObject.Properties['steps']) {
    throw 'Harness manifest must declare suites and steps objects.'
  }

  foreach ($stepProperty in $ManifestObject.steps.PSObject.Properties) {
    $stepId = $stepProperty.Name
    $step = $stepProperty.Value
    $kind = [string]$step.kind
    if ($kind -notin @('process', 'powershell')) {
      throw "Step '$stepId' has unsupported kind '$kind'."
    }
    if ($null -eq $step.PSObject.Properties['arguments']) {
      throw "Step '$stepId' must declare an arguments array."
    }
    $timeout = [int]$step.timeoutSeconds
    if ($timeout -lt 1 -or $timeout -gt 7200) {
      throw "Step '$stepId' timeoutSeconds must be between 1 and 7200."
    }
    $workingDirectory = Join-Path $RepositoryRoot ([string]$step.workingDirectory)
    if (-not (Test-Path -LiteralPath $workingDirectory -PathType Container)) {
      throw "Step '$stepId' working directory does not exist: $workingDirectory"
    }
    if ($kind -eq 'process' -and [string]::IsNullOrWhiteSpace([string]$step.command)) {
      throw "Step '$stepId' must declare command."
    }
    if ($kind -eq 'powershell') {
      $scriptPath = Join-Path $RepositoryRoot ([string]$step.script)
      if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Step '$stepId' script does not exist: $scriptPath"
      }
    }
    Assert-AllowedPlatform -Item $step -ItemName "Step '$stepId'" -Platform ''
  }

  foreach ($suiteProperty in $ManifestObject.suites.PSObject.Properties) {
    $null = Get-ExpandedStepIds -SuiteName $suiteProperty.Name -Suites $ManifestObject.suites -Steps $ManifestObject.steps -Platform ''
  }
}

function Get-CommandDisplay {
  param(
    [Parameter(Mandatory = $true)][object]$Step,
    [Parameter(Mandatory = $true)][string]$RepositoryRoot
  )

  $target = if ([string]$Step.kind -eq 'process') {
    [string]$Step.command
  } else {
    [string]$Step.script
  }
  $arguments = @($Step.arguments | ForEach-Object {
      $value = [string]$_
      if ($value -match '\s') { '"' + $value.Replace('"', '\"') + '"' } else { $value }
    })
  return (@($target) + $arguments) -join ' '
}

function ConvertTo-ProcessArgument {
  param([AllowEmptyString()][string]$Value)

  if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
    return $Value
  }
  $escaped = $Value -replace '(\\*)"', '$1$1\"'
  $escaped = $escaped -replace '(\\+)$', '$1$1'
  return '"' + $escaped + '"'
}

function Stop-HarnessProcessTree {
  param(
    [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
    [Parameter(Mandatory = $true)][string]$Platform
  )

  if ($Process.HasExited) {
    return
  }

  if ($PSVersionTable.PSVersion.Major -ge 7) {
    $Process.Kill($true)
  } elseif ($Platform -eq 'windows') {
    & taskkill.exe /PID $Process.Id /T /F *> $null
  } else {
    $Process.Kill()
  }
}

function Invoke-HarnessProcess {
  param(
    [Parameter(Mandatory = $true)][string]$InputFile,
    [Parameter(Mandatory = $true)][int]$TimeoutSeconds,
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][string]$Platform
  )

  $hostPath = (Get-Process -Id $PID).Path
  $arguments = [System.Collections.Generic.List[string]]::new()
  $arguments.Add('-NoProfile')
  if ($Platform -eq 'windows') {
    $arguments.Add('-ExecutionPolicy')
    $arguments.Add('Bypass')
  }
  $arguments.Add('-File')
  $arguments.Add($PSCommandPath)
  $arguments.Add('-InternalStepFile')
  $arguments.Add($InputFile)

  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $hostPath
  $startInfo.Arguments = (@($arguments) | ForEach-Object { ConvertTo-ProcessArgument -Value $_ }) -join ' '
  $startInfo.WorkingDirectory = $RepositoryRoot
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true

  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  $null = $process.Start()
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
  if ($timedOut) {
    Stop-HarnessProcessTree -Process $process -Platform $Platform
    $process.WaitForExit()
  }

  $stdout = $stdoutTask.GetAwaiter().GetResult()
  $stderr = $stderrTask.GetAwaiter().GetResult()
  $exitCode = if ($timedOut) { 124 } else { $process.ExitCode }
  $process.Dispose()

  return [pscustomobject]@{
    exitCode = $exitCode
    timedOut = $timedOut
    stdout = $stdout
    stderr = $stderr
  }
}

function Get-GitContext {
  param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

  $branch = (& git -C $RepositoryRoot rev-parse --abbrev-ref HEAD 2>$null)
  $commit = (& git -C $RepositoryRoot rev-parse HEAD 2>$null)
  $dirtyLines = @(& git -C $RepositoryRoot status --porcelain 2>$null)
  return [ordered]@{
    branch = if ($branch) { [string]$branch } else { $null }
    commit = if ($commit) { [string]$commit } else { $null }
    dirty = $dirtyLines.Count -gt 0
  }
}

function Test-StepPrerequisite {
  param(
    [Parameter(Mandatory = $true)][string]$StepId,
    [Parameter(Mandatory = $true)][object]$Step,
    [Parameter(Mandatory = $true)][string]$RepositoryRoot
  )

  if ([string]$Step.kind -eq 'process') {
    $resolved = Get-Command ([string]$Step.command) -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $resolved) {
      throw "Step '$StepId' requires command '$($Step.command)', but it is not available on PATH."
    }
    return [string]$resolved.Source
  }

  $scriptPath = Join-Path $RepositoryRoot ([string]$Step.script)
  if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw "Step '$StepId' requires missing script '$scriptPath'."
  }
  return $scriptPath
}

function Invoke-HarnessMain {
  $repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
  $configuredManifest = if ([string]::IsNullOrWhiteSpace($Manifest)) {
    Join-Path $PSScriptRoot 'harness.json'
  } else {
    $Manifest
  }
  $manifestPath = (Resolve-Path -LiteralPath $configuredManifest).Path
  $manifestObject = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $platform = Get-CurrentPlatform
  Assert-HarnessManifest -ManifestObject $manifestObject -RepositoryRoot $repositoryRoot -Platform $platform

  if ($List) {
    foreach ($suiteProperty in $manifestObject.suites.PSObject.Properties) {
      $suiteObject = $suiteProperty.Value
      $description = [string]$suiteObject.description
      Write-HarnessMessage -Message ("{0,-14} {1}" -f $suiteProperty.Name, $description)
    }
    return 0
  }

  $suiteObject = Get-NamedValue -Container $manifestObject.suites -Name $Suite -ContainerName 'suite'
  Assert-AllowedPlatform -Item $suiteObject -ItemName "Suite '$Suite'" -Platform $platform
  $stepIds = @(Get-ExpandedStepIds -SuiteName $Suite -Suites $manifestObject.suites -Steps $manifestObject.steps -Platform $platform)
  if ($stepIds.Count -eq 0) {
    throw "Suite '$Suite' expands to no steps."
  }

  $prerequisites = [System.Collections.Generic.List[object]]::new()
  foreach ($stepId in $stepIds) {
    $step = Get-NamedValue -Container $manifestObject.steps -Name $stepId -ContainerName 'step'
    $resolved = Test-StepPrerequisite -StepId $stepId -Step $step -RepositoryRoot $repositoryRoot
    $prerequisites.Add([ordered]@{ step = $stepId; resolved = $resolved })
  }

  if ($Doctor) {
    Write-HarnessMessage -Message "Harness manifest: $manifestPath" -Color Cyan
    Write-HarnessMessage -Message "Repository: $repositoryRoot" -Color Cyan
    Write-HarnessMessage -Message "Platform: $platform" -Color Cyan
    Write-HarnessMessage -Message "Suite: $Suite ($($stepIds.Count) steps)" -Color Cyan
    foreach ($item in $prerequisites) {
      Write-HarnessMessage -Message "[ok] $($item.step) -> $($item.resolved)" -Color Green
    }
    return 0
  }

  $configuredArtifacts = if ([string]::IsNullOrWhiteSpace($ArtifactsRoot)) {
    [string]$manifestObject.artifactDirectory
  } else {
    $ArtifactsRoot
  }
  $artifactBase = if ([IO.Path]::IsPathRooted($configuredArtifacts)) {
    [IO.Path]::GetFullPath($configuredArtifacts)
  } else {
    [IO.Path]::GetFullPath((Join-Path $repositoryRoot $configuredArtifacts))
  }
  $runId = "$((Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ'))-$PID"
  $runDirectory = Join-Path $artifactBase $runId
  $null = New-Item -ItemType Directory -Path $runDirectory -Force

  $runStarted = [DateTime]::UtcNow
  $stepResults = [System.Collections.Generic.List[object]]::new()
  $failed = $false
  Write-HarnessMessage -Message "Harness suite '$Suite' started. RunId=$runId" -Color Cyan

  for ($index = 0; $index -lt $stepIds.Count; $index++) {
    $stepId = $stepIds[$index]
    $step = Get-NamedValue -Container $manifestObject.steps -Name $stepId -ContainerName 'step'
    $ordinal = $index + 1
    $safeStepId = $stepId -replace '[^A-Za-z0-9_.-]', '_'
    $logName = ('{0:D2}-{1}.log' -f $ordinal, $safeStepId)
    $logPath = Join-Path $runDirectory $logName
    $inputPath = Join-Path $runDirectory ('{0:D2}-{1}.input.json' -f $ordinal, $safeStepId)
    $commandDisplay = Get-CommandDisplay -Step $step -RepositoryRoot $repositoryRoot

    if ($failed -and -not $KeepGoing) {
      $stepResults.Add([ordered]@{
          id = $stepId
          status = 'skipped'
          exitCode = $null
          durationMs = 0
          command = $commandDisplay
          log = $null
        })
      continue
    }

    Write-HarnessMessage -Message "[$ordinal/$($stepIds.Count)] $stepId" -Color Yellow
    if ($DryRun) {
      Write-HarnessMessage -Message "  plan: $commandDisplay" -Color DarkGray
      $stepResults.Add([ordered]@{
          id = $stepId
          status = 'planned'
          exitCode = $null
          durationMs = 0
          command = $commandDisplay
          log = $null
        })
      continue
    }

    $workingDirectory = [IO.Path]::GetFullPath((Join-Path $repositoryRoot ([string]$step.workingDirectory)))
    $payload = [ordered]@{
      kind = [string]$step.kind
      command = if ([string]$step.kind -eq 'process') { [string]$step.command } else { $null }
      script = if ([string]$step.kind -eq 'powershell') { [IO.Path]::GetFullPath((Join-Path $repositoryRoot ([string]$step.script))) } else { $null }
      arguments = @($step.arguments | ForEach-Object { [string]$_ })
      workingDirectory = $workingDirectory
    }
    $payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $inputPath -Encoding UTF8

    $stepStarted = [DateTime]::UtcNow
    $processResult = Invoke-HarnessProcess -InputFile $inputPath -TimeoutSeconds ([int]$step.timeoutSeconds) -RepositoryRoot $repositoryRoot -Platform $platform
    $durationMs = [int64]([DateTime]::UtcNow - $stepStarted).TotalMilliseconds
    $logLines = [System.Collections.Generic.List[string]]::new()
    $logLines.Add("step=$stepId")
    $logLines.Add("command=$commandDisplay")
    $logLines.Add("workingDirectory=$workingDirectory")
    $logLines.Add("timeoutSeconds=$($step.timeoutSeconds)")
    $logLines.Add('--- stdout ---')
    $logLines.Add([string]$processResult.stdout)
    $logLines.Add('--- stderr ---')
    $logLines.Add([string]$processResult.stderr)
    $logLines | Set-Content -LiteralPath $logPath -Encoding UTF8

    $status = if ($processResult.timedOut) {
      'timed_out'
    } elseif ($processResult.exitCode -eq 0) {
      'passed'
    } else {
      'failed'
    }
    $stepResults.Add([ordered]@{
        id = $stepId
        status = $status
        exitCode = [int]$processResult.exitCode
        durationMs = $durationMs
        command = $commandDisplay
        log = $logName
      })

    if ($VerboseSteps -or $status -ne 'passed') {
      if (-not [string]::IsNullOrWhiteSpace([string]$processResult.stdout)) {
        Write-HarnessMessage -Message (([string]$processResult.stdout).TrimEnd())
      }
      if (-not [string]::IsNullOrWhiteSpace([string]$processResult.stderr)) {
        Write-HarnessMessage -Message (([string]$processResult.stderr).TrimEnd()) -Color DarkYellow
      }
    }

    if ($status -eq 'passed') {
      Write-HarnessMessage -Message "  passed in $durationMs ms" -Color Green
    } else {
      $failed = $true
      Write-HarnessMessage -Message "  $status (exit=$($processResult.exitCode)); log=$logPath" -Color Red
    }
  }

  $runFinished = [DateTime]::UtcNow
  $summary = [ordered]@{
    schemaVersion = 1
    runId = $runId
    suite = $Suite
    platform = $platform
    dryRun = [bool]$DryRun
    keepGoing = [bool]$KeepGoing
    success = -not $failed
    startedAtUtc = $runStarted.ToString('o')
    finishedAtUtc = $runFinished.ToString('o')
    durationMs = [int64]($runFinished - $runStarted).TotalMilliseconds
    repositoryRoot = $repositoryRoot
    git = Get-GitContext -RepositoryRoot $repositoryRoot
    manifest = [ordered]@{
      path = $manifestPath
      sha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    steps = @($stepResults)
  }
  $summaryPath = Join-Path $runDirectory 'summary.json'
  $summaryJson = $summary | ConvertTo-Json -Depth 8
  $summaryJson | Set-Content -LiteralPath $summaryPath -Encoding UTF8

  if ($OutputFormat -eq 'Json') {
    Write-Output $summaryJson
  } else {
    $resultLabel = if ($failed) { 'FAILED' } else { if ($DryRun) { 'PLANNED' } else { 'PASSED' } }
    $color = if ($failed) { [ConsoleColor]::Red } else { [ConsoleColor]::Green }
    Write-HarnessMessage -Message "Harness $resultLabel. Summary=$summaryPath" -Color $color
  }
  if ($failed) { return 1 }
  return 0
}

try {
  if ($List -and $Doctor) {
    throw 'Use either -List or -Doctor, not both.'
  }
  $mainOutput = @(Invoke-HarnessMain)
  if ($mainOutput.Count -eq 0) {
    exit 0
  }
  $mainExitCode = [int]$mainOutput[$mainOutput.Count - 1]
  if ($mainOutput.Count -gt 1) {
    $mainOutput[0..($mainOutput.Count - 2)] | Write-Output
  }
  exit $mainExitCode
} catch {
  if ($OutputFormat -eq 'Json') {
    [ordered]@{
      schemaVersion = 1
      success = $false
      error = $_.Exception.Message
    } | ConvertTo-Json -Depth 4 | Write-Output
  } else {
    Write-Error $_
  }
  exit 1
}
