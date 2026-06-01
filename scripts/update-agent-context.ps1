<#
.SYNOPSIS
  Incrementally update AGENTS.md (shared persistent context for all AI agents).
.DESCRIPTION
  Meant to run after /plan writes plan.md. Only the AUTO block is machine-managed;
  anything outside the AUTO markers (your hand-written notes) is preserved. The tech
  stack is accumulated with de-duplication; recent changes are kept newest-first,
  capped at KEEP entries.
  Design: parsing plan.md tables is brittle, so the designer (agent) passes the
  already-decided facts as arguments; this script only does the mechanical
  merge / preserve / trim. Output strings are kept ASCII so this matches the bash
  version byte-for-byte and never garbles under Windows PowerShell 5.1 (CP932).
.EXAMPLE
  scripts/update-agent-context.ps1 -Feature 003-user-auth -Tech "Go 1.22","chi" -Summary "JWT auth"
#>
param(
  [string]$Feature,
  [string[]]$Tech = @(),
  [string]$Summary
)
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrEmpty($Feature)) {
  [Console]::Error.WriteLine("usage: update-agent-context.ps1 -Feature <NNN-slug> [-Tech a,b] [-Summary S]")
  exit 1
}

$root = Split-Path -Parent $PSScriptRoot
$file = Join-Path $root "AGENTS.md"
$keep = 5

$markBegin = '<!-- AUTO:BEGIN (managed by scripts/update-agent-context; manual edits here are overwritten) -->'
$markEnd   = '<!-- AUTO:END -->'

$defaultHead = @(
  '# AGENTS.md - Project context (shared memory for AI agents)',
  '',
  '<!-- All agents (Claude / Cursor / Copilot / Gemini, etc.) read this persistent',
  '     context. The AUTO block below is maintained by scripts/update-agent-context',
  '     on every /plan. Anything OUTSIDE the AUTO markers is yours to edit by hand',
  '     and is preserved across updates. -->'
)

# Split an existing file into head / auto-body / tail. Read as UTF-8 so hand-written
# non-ASCII content is not mis-decoded as CP932 by Windows PowerShell 5.1.
$headLines = @(); $tailLines = @(); $autoLines = @()
$haveBlock  = $false
$fileExists = Test-Path -LiteralPath $file
if ($fileExists) {
  $text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
  $all  = @($text -split "\r?\n")
  if ($all.Count -gt 1 -and $all[$all.Count - 1] -eq '') { $all = @($all[0..($all.Count - 2)]) }
  $bi = -1; $ei = -1
  for ($i = 0; $i -lt $all.Count; $i++) {
    if ($bi -lt 0 -and $all[$i].StartsWith('<!-- AUTO:BEGIN')) { $bi = $i }
    if ($all[$i].StartsWith('<!-- AUTO:END -->')) { $ei = $i }
  }
  if ($bi -ge 0 -and $ei -gt $bi) {
    $haveBlock = $true
    if ($bi -gt 0) { $headLines = @($all[0..($bi - 1)]) }
    if (($ei - $bi - 1) -gt 0) { $autoLines = @($all[($bi + 1)..($ei - 1)]) }
    if (($ei + 1) -le ($all.Count - 1)) { $tailLines = @($all[($ei + 1)..($all.Count - 1)]) }
  } else {
    if ($all.Count -gt 0) { $headLines = @($all) }
  }
}

# Read the existing tech stack / recent changes out of the current AUTO block.
$section = ''
$existingTech = @(); $existingRecent = @()
foreach ($ln in $autoLines) {
  if ($ln.StartsWith('## Active tech stack')) { $section = 'tech';   continue }
  if ($ln.StartsWith('## Recent changes'))    { $section = 'recent'; continue }
  if ($ln.StartsWith('## '))                  { $section = '';       continue }
  if ($ln -eq '- (none yet)') { continue }
  if ($ln.StartsWith('- ')) {
    if     ($section -eq 'tech')   { $existingTech   += $ln.Substring(2) }
    elseif ($section -eq 'recent') { $existingRecent += $ln }
  }
}

# Merge the tech stack, preserving order and de-duplicating.
$mergedTech = @()
foreach ($t in $existingTech) { $mergedTech += $t }
foreach ($t in $Tech) {
  if ([string]::IsNullOrEmpty($t)) { continue }
  if ($mergedTech -notcontains $t) { $mergedTech += $t }
}

# Recent changes: drop any prior entry for the same feature, prepend, cap at KEEP.
$newRecent = "- $Feature"
if (-not [string]::IsNullOrEmpty($Summary)) { $newRecent = "- ${Feature}: $Summary" }
$filtered = @()
foreach ($ln in $existingRecent) {
  if ($ln -eq "- $Feature" -or $ln.StartsWith("- ${Feature}:")) { continue }
  $filtered += $ln
}
$recent = @($newRecent) + $filtered
if ($recent.Count -gt $keep) { $recent = @($recent[0..($keep - 1)]) }

# Rebuild the AUTO block.
$block = @()
$block += $markBegin
$block += '## Active tech stack'
$block += ''
if ($mergedTech.Count -gt 0) { foreach ($t in $mergedTech) { $block += "- $t" } }
else { $block += '- (none yet)' }
$block += ''
$block += '## Recent changes'
$block += ''
foreach ($ln in $recent) { $block += $ln }
$block += $markEnd

# Assemble head + block + tail.
$out = @()
if ($haveBlock) {
  if ($headLines.Count -gt 0) { $out += $headLines }
} elseif ($fileExists) {
  if ($headLines.Count -gt 0) { $out += $headLines }
  $out += ''   # separate existing hand-written body from the appended block
} else {
  $out += $defaultHead
  $out += ''
}
$out += $block
if ($tailLines.Count -gt 0) { $out += $tailLines }

# Write as UTF-8 without BOM, LF line endings (to match the bash version exactly).
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($file, (($out -join "`n") + "`n"), $utf8)

# Confirmation goes to stderr; stdout stays quiet.
[Console]::Error.WriteLine("AGENTS.md updated (feature: $Feature; tech entries: $($mergedTech.Count))")
exit 0
