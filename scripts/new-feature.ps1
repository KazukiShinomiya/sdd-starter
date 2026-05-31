<#
.SYNOPSIS
  Allocate the next sequence number and create specs/NNN-feature-name/, then return its path.
.DESCRIPTION
  Pass an ASCII kebab-case feature name (e.g. "user-auth"). The human-readable title
  (Japanese, etc.) belongs inside spec.md, not in the directory name, to keep the
  identifier portable across git / CI / other OSes.
  NOTE: comments and messages are kept ASCII on purpose so Windows PowerShell 5.1
  (which reads BOM-less UTF-8 as CP932) never garbles this script.
.EXAMPLE
  scripts/new-feature.ps1 -Name "user-auth"
#>
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Name
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

$dir = Join-Path $specs "$next-$slug"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Return the absolute path of the created directory (the caller/agent uses it).
Write-Output $dir
