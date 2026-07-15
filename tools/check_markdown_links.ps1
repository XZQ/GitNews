param(
  [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$errors = [System.Collections.Generic.List[string]]::new()
$ignoredSegments = @('.git', '.dart_tool', '.venv', 'build')

Get-ChildItem -LiteralPath $rootPath -Recurse -Filter '*.md' -File |
  Where-Object {
    $relative = $_.FullName.Substring($rootPath.Length).TrimStart([char]92, [char]47)
    -not ($ignoredSegments | Where-Object { $relative -match "(^|[\\/])$([regex]::Escape($_))([\\/]|$)" })
  } |
  ForEach-Object {
    $file = $_
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    [regex]::Matches($content, '\[[^\]]+\]\((?<target>[^)]+)\)') |
      ForEach-Object {
        $target = $_.Groups['target'].Value.Trim('<', '>')
        if ($target -match '^(https?://|mailto:|app://|#)') {
          return
        }
        $target = [Uri]::UnescapeDataString(($target -split '#')[0])
        if ([string]::IsNullOrWhiteSpace($target)) {
          return
        }
        $resolved = Join-Path -Path $file.DirectoryName -ChildPath $target
        if (-not (Test-Path -LiteralPath $resolved)) {
          $relativeFile = $file.FullName.Substring($rootPath.Length).TrimStart([char]92, [char]47)
          $errors.Add("${relativeFile}: $target")
        }
      }
  }

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error "Broken Markdown link: $_" }
  exit 1
}

Write-Output 'Markdown local links passed.'
