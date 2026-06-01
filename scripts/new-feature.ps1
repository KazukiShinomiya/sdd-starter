<#
.SYNOPSIS
  Allocate the next sequence number and create specs/NNN-feature-name/, then return its path.
.DESCRIPTION
  Pass an ASCII kebab-case feature name (e.g. "user-auth"). The human-readable title
  (Japanese, etc.) belongs inside spec.md, not in the directory name, to keep the
  identifier portable across git / CI / other OSes.
  It also copies templates/spec-template.md to spec.md to seed the writing.
  By default it also creates and checks out a per-feature git branch NNN-feature-name
  (so one feature == one branch == one PR). Pass -NoBranch to suppress that.
  NOTE: comments and messages are kept ASCII on purpose so Windows PowerShell 5.1
  (which reads BOM-less UTF-8 as CP932) never garbles this script.
.EXAMPLE
  scripts/new-feature.ps1 -Name "user-auth"
.EXAMPLE
  scripts/new-feature.ps1 -Name "user-auth" -NoBranch
#>
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Name,
  [switch]$NoBranch
)
$ErrorActionPreference = "Stop"

# Normalize to ASCII kebab-case: lower-case, non-alphanumerics to hyphens, trim hyphens.
$slug = ($Name.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if ([string]::IsNullOrEmpty($slug)) {
  Write-Error "Feature name has no ASCII alphanumerics: '$Name'. Pass a kebab-case name like 'user-auth'."
  exit 1
}

# Resolve specs/ relative to the repository root (one level above this script).
$root  = Split-Path -Parent $PSScriptRoot
$specs = Join-Path $root "specs"
New-Item -ItemType Directory -Force -Path $specs | Out-Null

# Find the highest leading number among existing dirs, then add one (zero-padded to 3).
$max = 0
Get-ChildItem -Path $specs -Directory | ForEach-Object {
  if ($_.Name -match '^(\d+)-') {
    $n = [int]$Matches[1]
    if ($n -gt $max) { $max = $n }
  }
}
$next = '{0:D3}' -f ($max + 1)

# Run git quietly and return its real exit code. Windows PowerShell 5.1 wraps a native
# command's stderr into ErrorRecords, which would terminate under ErrorActionPreference=Stop;
# we localize it to Continue and judge success by $LASTEXITCODE, not $?.
function Invoke-GitQuiet {
  param([Parameter(Mandatory = $true)][string[]]$GitArgs)
  $old = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & git @GitArgs 2>&1 | Out-Null
    return $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $old
  }
}

# Move onto a per-feature git branch NNN-feature-name before creating the directory,
# so spec.md is born on the feature branch. Best-effort: numbering continues on failure.
# stdout is reserved for the path, so every report here goes to stderr via Console.Error
# (Write-Error would terminate under $ErrorActionPreference = "Stop").
$branch = "$next-$slug"
if (-not $NoBranch) {
  if ((Invoke-GitQuiet @('-C', $root, 'rev-parse', '--is-inside-work-tree')) -eq 0) {
    if ((Invoke-GitQuiet @('-C', $root, 'show-ref', '--verify', '--quiet', "refs/heads/$branch")) -eq 0) {
      # Existing branch: do not recreate, just switch onto it (idempotent re-runs).
      $rc = Invoke-GitQuiet @('-C', $root, 'switch', $branch)
      if ($rc -ne 0) { $rc = Invoke-GitQuiet @('-C', $root, 'checkout', $branch) }
      if ($rc -eq 0) {
        [Console]::Error.WriteLine("branch: switched to existing '$branch'")
      } else {
        [Console]::Error.WriteLine("warning: could not switch to existing branch '$branch'; staying put")
      }
    } else {
      # New branch from current HEAD (switch is newer git, checkout is the fallback).
      $rc = Invoke-GitQuiet @('-C', $root, 'switch', '-c', $branch)
      if ($rc -ne 0) { $rc = Invoke-GitQuiet @('-C', $root, 'checkout', '-b', $branch) }
      if ($rc -eq 0) {
        [Console]::Error.WriteLine("branch: created and switched to '$branch'")
      } else {
        [Console]::Error.WriteLine("warning: could not create branch '$branch'; staying on current branch")
      }
    }
  } else {
    [Console]::Error.WriteLine("note: not a git repository; skipped branch creation")
  }
}

$dir = Join-Path $specs "$next-$slug"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Seed spec.md from the template (only if it exists and is not already there).
# stdout is reserved for the path, so this copy stays a silent side effect.
$template = Join-Path $root "templates\spec-template.md"
$specFile = Join-Path $dir "spec.md"
if ((Test-Path $template) -and -not (Test-Path $specFile)) {
  Copy-Item -Path $template -Destination $specFile
}

# Return the absolute path of the created directory (the caller/agent uses it).
Write-Output $dir

# Exit cleanly. A best-effort git probe above may have left $LASTEXITCODE non-zero
# (e.g. 128 in a non-git dir); without this, callers could misread success as failure.
exit 0
