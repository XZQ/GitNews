param(
  [string]$Root = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$errors = [System.Collections.Generic.List[string]]::new()

$testRoot = Join-Path $rootPath 'test'
$machineLocalPatterns = @(
  'C:[\\/]Windows[\\/]Fonts',
  '[A-Za-z]:[\\/](flutter_sdk|flutter_pub_cache)([\\/]|$)'
)

Get-ChildItem -LiteralPath $testRoot -Recurse -Filter '*.dart' -File |
  ForEach-Object {
    $file = $_
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($pattern in $machineLocalPatterns) {
      if ($content -match $pattern) {
        $relative = $file.FullName.Substring($rootPath.Length).TrimStart([char]92, [char]47)
        $errors.Add("${relative}: contains a machine-local font or Flutter path")
        break
      }
    }
  }

$xcodeProject = Join-Path $rootPath 'macos/Runner.xcodeproj/project.pbxproj'
$objectDefinitions = [regex]::Matches(
  (Get-Content -LiteralPath $xcodeProject -Raw -Encoding UTF8),
  '(?m)^\s*(?<id>[A-F0-9]{24}) /\*.*?\*/ = \{isa = '
)
$duplicateObjectIds = @(
  $objectDefinitions |
    ForEach-Object { $_.Groups['id'].Value } |
    Group-Object |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object { $_.Name }
)
foreach ($objectId in $duplicateObjectIds) {
  $errors.Add("macos/Runner.xcodeproj/project.pbxproj: duplicate object definition $objectId")
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error "Repository portability check failed: $_" }
  exit 1
}

Write-Output 'Repository portability checks passed.'
