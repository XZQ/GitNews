param(
  [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$errors = [System.Collections.Generic.List[string]]::new()
$ignoredSegments = @('.git', '.dart_tool', '.venv', 'build', 'ephemeral', '.pytest_cache', '.ruff_cache')

# Walk the tree directory by directory so ignored or unreadable artifact
# directories (e.g. server/.pytest_cache, which denies even READ_CONTROL) are
# pruned before descent instead of aborting the whole scan.
$pendingDirs = [System.Collections.Generic.Stack[string]]::new()
$pendingDirs.Push($rootPath)
$markdownFiles = [System.Collections.Generic.List[string]]::new()
while ($pendingDirs.Count -gt 0) {
  $dir = $pendingDirs.Pop()
  try {
    $children = Get-ChildItem -LiteralPath $dir
  } catch [System.UnauthorizedAccessException] {
    continue
  }
  foreach ($child in $children) {
    if ($child.PSIsContainer) {
      if ($ignoredSegments -notcontains $child.Name) {
        $pendingDirs.Push($child.FullName)
      }
    } elseif ($child.Extension -ieq '.md') {
      $markdownFiles.Add($child.FullName)
    }
  }
}

foreach ($filePath in $markdownFiles) {
    $file = Get-Item -LiteralPath $filePath
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
