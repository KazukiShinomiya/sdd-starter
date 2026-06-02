<#
.SYNOPSIS
  Check the structural integrity of the template (zero-dependency, read-only).
.DESCRIPTION
  Mirrors scripts/check.sh for Windows. Verifies that:
    - each of the 4 agent entry dirs matches prompts/ exactly (no missing/extra),
    - every entry references an existing prompts/*.md (no broken links),
    - every *-template.md reference resolves.
  Exits non-zero when any check fails.
  NOTE: comments/messages are ASCII on purpose (Windows PowerShell 5.1 reads
  BOM-less UTF-8 as CP932), but NG/OK detail strings may include the offending paths.
#>
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$fail = $false
function Fail($m) { Write-Host "NG: $m"; $script:fail = $true }
function Pass($m) { Write-Host "OK: $m" }

# Canonical command set = base names of prompts/*.md
$cmds = Get-ChildItem prompts/*.md | ForEach-Object { $_.BaseName } | Sort-Object

function Check-Agent($label, $dir, $suffix) {
  $present = Get-ChildItem (Join-Path $dir "*$suffix") -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Name.Substring(0, $_.Name.Length - $suffix.Length) } | Sort-Object
  $diff = Compare-Object $cmds $present
  if (-not $diff) {
    Pass "${label}: all commands match ($($cmds.Count))"
  } else {
    Fail "${label}: command set differs from prompts/"
    $diff | ForEach-Object {
      $side = if ($_.SideIndicator -eq '<=') { 'prompts only' } else { 'entry only' }
      Write-Host "      [$side] $($_.InputObject)"
    }
  }
}
Check-Agent "claude" ".claude/commands" ".md"
Check-Agent "cursor" ".cursor/commands" ".md"
Check-Agent "github" ".github/prompts"  ".prompt.md"
Check-Agent "gemini" ".gemini/commands" ".toml"

# Entries must reference existing prompts/*.md
$refs = Get-ChildItem -Recurse -File .claude, .cursor, .github, .gemini |
  Select-String -Pattern 'prompts/[a-z]+\.md' -AllMatches |
  ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
$broken = $false
foreach ($r in $refs) { if (-not (Test-Path $r)) { Fail "broken link: entry references missing $r"; $broken = $true } }
if (-not $broken) { Pass "no broken entry -> prompts links" }

# *-template.md references must resolve
$trefs = Get-ChildItem -Recurse -File prompts, templates, README.md |
  Select-String -Pattern '[a-z-]+-template\.md' -AllMatches |
  ForEach-Object { $_.Matches.Value } | Sort-Object -Unique
$tbroken = $false
foreach ($r in $trefs) { if (-not (Test-Path (Join-Path "templates" $r))) { Fail "broken link: missing templates/$r"; $tbroken = $true } }
if (-not $tbroken) { Pass "no broken template references" }

# Every prompts/*.md must carry the 4 required sections (structural gate).
# prompts/ is the single source of truth, so a missing section ripples to all
# agents. The optional "next step" section is not required (terminal commands omit it).
# NOTE: the section names below are Japanese, so this file is saved as UTF-8 WITH BOM
# (unlike its ASCII-only sibling scripts) and target files are read as UTF-8 explicitly,
# so Windows PowerShell 5.1 never mis-reads them as CP932.
$required = @("## 入力", "## 手順", "## 出力", "## 禁止")
$pbroken = $false
foreach ($f in Get-ChildItem prompts/*.md) {
  $lines = @([System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8) -split "\r?\n")
  foreach ($sec in $required) {
    if ($lines -notcontains $sec) { Fail "prompts structure: $($f.Name) is missing section '$sec'"; $pbroken = $true }
  }
}
if (-not $pbroken) { Pass "prompts: every prompt has the 4 required sections" }

Write-Host ""
if ($fail) { Write-Host "Checks failed. Fix the NG items above."; exit 1 }
Write-Host "All checks passed."
exit 0
