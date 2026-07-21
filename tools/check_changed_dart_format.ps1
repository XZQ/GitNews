param(
  [string]$Root = (Get-Location).Path,
  [string]$BaseRef
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

function Invoke-GitPathQuery {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)

  $output = @(& git -C $rootPath @Arguments)
  if ($LASTEXITCODE -ne 0) {
    throw "Git path query failed: git $($Arguments -join ' ')"
  }
  return $output
}

function Add-DartPaths {
  param([AllowEmptyCollection()][string[]]$Candidates)

  foreach ($candidate in @($Candidates)) {
    $relative = ([string]$candidate).Replace('\', '/').Trim()
    if ($relative -notmatch '^(lib|test)/.+\.dart$') {
      continue
    }
    $fullPath = [IO.Path]::GetFullPath((Join-Path $rootPath $relative))
    $rootPrefix = $rootPath.TrimEnd([char]92, [char]47) + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Git returned a Dart path outside the repository: $relative"
    }
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
      $null = $paths.Add($relative)
    }
  }
}

if ([string]::IsNullOrWhiteSpace($BaseRef)) {
  if (-not [string]::IsNullOrWhiteSpace($env:HARNESS_BASE_REF)) {
    $BaseRef = $env:HARNESS_BASE_REF
  } elseif (-not [string]::IsNullOrWhiteSpace($env:GITHUB_BASE_REF)) {
    $BaseRef = "origin/$($env:GITHUB_BASE_REF)"
  }
}

if (-not [string]::IsNullOrWhiteSpace($BaseRef) -and $BaseRef -notmatch '^0+$') {
  & git -C $rootPath rev-parse --verify "$BaseRef^{commit}" *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "Dart format base ref is unavailable: $BaseRef"
  }
  Add-DartPaths -Candidates (Invoke-GitPathQuery -Arguments @('diff', '--name-only', '--diff-filter=ACMR', "$BaseRef...HEAD", '--', 'lib', 'test'))
}

Add-DartPaths -Candidates (Invoke-GitPathQuery -Arguments @('diff', '--name-only', '--diff-filter=ACMR', '--', 'lib', 'test'))
Add-DartPaths -Candidates (Invoke-GitPathQuery -Arguments @('diff', '--cached', '--name-only', '--diff-filter=ACMR', '--', 'lib', 'test'))
Add-DartPaths -Candidates (Invoke-GitPathQuery -Arguments @('ls-files', '--others', '--exclude-standard', '--', 'lib', 'test'))

$dartFiles = @($paths | Sort-Object)
if ($dartFiles.Count -eq 0) {
  Write-Output 'Changed Dart format check passed: no changed Dart files.'
  exit 0
}

Push-Location -LiteralPath $rootPath
try {
  & dart format --output=none --set-exit-if-changed @dartFiles
  $exitCode = $LASTEXITCODE
} finally {
  Pop-Location
}

if ($exitCode -ne 0) {
  Write-Error "Changed Dart format check failed for $($dartFiles.Count) file(s)."
  exit $exitCode
}

Write-Output "Changed Dart format check passed for $($dartFiles.Count) file(s)."
