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

# Each entry must reference the prompts/*.md that matches its OWN name (mis-wiring guard).
# Passing both the name-set check and the broken-link check still lets a "specify"
# entry silently point at prompts/plan.md. Close that gap.
$mismatch = $false
function Check-SelfRef($label, $dir, $suffix) {
  foreach ($f in Get-ChildItem (Join-Path $dir "*$suffix") -ErrorAction SilentlyContinue) {
    $name = $f.Name.Substring(0, $f.Name.Length - $suffix.Length)
    $body = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($body -notmatch "prompts/$name\.md([^a-z]|$)") {
      Fail "${label}: entry $($f.Name) does not reference its own prompt (prompts/$name.md)"
      $script:mismatch = $true
    }
  }
}
Check-SelfRef "claude" ".claude/commands" ".md"
Check-SelfRef "cursor" ".cursor/commands" ".md"
Check-SelfRef "github" ".github/prompts"  ".prompt.md"
Check-SelfRef "gemini" ".gemini/commands" ".toml"
if (-not $mismatch) { Pass "each entry references its own prompt" }

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

# Template's required headings (source of truth). Both the examples freshness gate and the
# self-consistency gate below reference this single definition, so headings are never copied
# twice inside the check script. Sections a small feature may legitimately omit (tasks phases)
# are not required; sec.8/9 are optional and handled separately. Headings are Japanese.
$specHeads = @("## 1. 概要","## 2. なぜ","## 3. ユーザーストーリー","## 4. スコープ","## 5. 非機能要件","## 6. 未決定事項","## 7. 憲法との整合")
$planHeads = @("## 1. 技術スタック","## 2. アーキテクチャ概要","## 3. データモデル","## 4. インターフェース","## 5. 主要な設計判断","## 6. Constitution Check","## 7. リスクと未確定事項")
$tasksHeads = @("## 凡例","## トレーサビリティ")
$specTraceHeads = @("## 8. 明確化ログ","## 9. 改訂履歴")

# Self-consistency gate: are the headings check requires actually present in the templates
# (the source of truth)? Catches the drift where a template renames/removes a heading but this
# check list stays stale. Without it, only "do examples follow check's list" is verified, never
# "does check follow the template" -- a blind spot where the freshness gate cannot keep itself
# fresh. Substring match absorbs parenthetical variation.
$tsync = $false
function Check-TemplateSync($template, $heads) {
  if (-not (Test-Path $template)) { Fail "template sync: $template not found"; $script:tsync = $true; return }
  $text = [System.IO.File]::ReadAllText($template, [System.Text.Encoding]::UTF8)
  foreach ($h in $heads) {
    if (-not $text.Contains($h)) { Fail "template sync: $template is missing required heading '$h' (check list drifted from template)"; $script:tsync = $true }
  }
}
Check-TemplateSync "templates/spec-template.md"  ($specHeads + $specTraceHeads)
Check-TemplateSync "templates/plan-template.md"  $planHeads
Check-TemplateSync "templates/tasks-template.md" $tasksHeads
if (-not $tsync) { Pass "check's required headings match the templates (self-consistency with source of truth)" }

# examples/ must track the template skeleton (teaching-material freshness gate).
# examples are dogfooded teaching material; catch the drift where a template heading
# evolves but an example is left behind. The match basis reuses the source of truth above
# (*Heads). Match by literal substring so both lungs behave identically.
$ebroken = $false
function Check-Doc($file, $heads) {
  if (-not (Test-Path $file)) { return }   # skip artifacts an example has not produced
  $text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
  foreach ($h in $heads) {
    if (-not $text.Contains($h)) { Fail "examples freshness: $file is missing heading '$h'"; $script:ebroken = $true }
  }
}
# A clarify/amend example must carry the trace (heading) and the back-reference together.
# A heading without "-> section" refs (or vice versa) is a half-wired teaching example.
# Examples without sec.8/9 (the smoothly-flowing ones) pass untouched -> library-loan independent.
function Check-Trace($file, $heading, $ref) {
  if (-not (Test-Path $file)) { return }
  $text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
  if ($text.Contains($heading) -ne $text.Contains($ref)) {
    Fail "examples freshness: $file must carry heading '$heading' and reference '$ref' together"
    $script:ebroken = $true
  }
}
foreach ($d in Get-ChildItem examples -Directory) {
  Check-Doc (Join-Path $d.FullName "spec.md")  $specHeads
  Check-Doc (Join-Path $d.FullName "plan.md")  $planHeads
  Check-Doc (Join-Path $d.FullName "tasks.md") $tasksHeads
  Check-Trace (Join-Path $d.FullName "spec.md") $specTraceHeads[0] "→ §8"
  Check-Trace (Join-Path $d.FullName "spec.md") $specTraceHeads[1] "→ §9"
}
if (-not $ebroken) { Pass "examples track the template skeleton (required headings)" }

Write-Host ""
if ($fail) { Write-Host "Checks failed. Fix the NG items above."; exit 1 }
Write-Host "All checks passed."
exit 0
