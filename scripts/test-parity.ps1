<#
.SYNOPSIS
  Parity test for the PowerShell helper scripts (zero-dependency).
.DESCRIPTION
  Mirrors scripts/test-parity.sh on Windows. Verifies:
    - new-feature.ps1          : slug normalization and sequential numbering
    - update-agent-context.ps1 : AGENTS.md generation (dedupe / KEEP trim / preserve)
  Both bash and PS versions compare against the SAME tests/golden and tests/fixtures,
  so passing the identical golden byte-for-byte proves the two implementations behave
  equivalently. Runs in a temp sandbox so the real specs/ and AGENTS.md are untouched.
  NOTE: this file is saved as UTF-8 WITH BOM because it contains a Japanese slug
  literal; the helper scripts are invoked as CHILD processes so their `exit` does not
  terminate this runner, and so a mis-encoded Japanese arg cannot abort the run
  (new-feature's slug is [^a-z0-9]-stripped, hence robust to argument encoding).
#>
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$fail = $false
function Fail($m) { Write-Host "NG: $m"; $script:fail = $true }
function Pass($m) { Write-Host "OK: $m" }

function Test-ByteEqual($a, $b) {
  if (-not (Test-Path $a) -or -not (Test-Path $b)) { return $false }
  $ba = [System.IO.File]::ReadAllBytes($a)
  $bb = [System.IO.File]::ReadAllBytes($b)
  if ($ba.Length -ne $bb.Length) { return $false }
  for ($i = 0; $i -lt $ba.Length; $i++) { if ($ba[$i] -ne $bb[$i]) { return $false } }
  return $true
}

$sb = Join-Path ([System.IO.Path]::GetTempPath()) ("parity-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path (Join-Path $sb "scripts")   | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $sb "templates") | Out-Null
Copy-Item "$root\scripts\new-feature.ps1"          (Join-Path $sb "scripts")
Copy-Item "$root\scripts\update-agent-context.ps1" (Join-Path $sb "scripts")
Copy-Item "$root\templates\spec-template.md"       (Join-Path $sb "templates")

$nfScript = Join-Path $sb "scripts\new-feature.ps1"
$ucScript = Join-Path $sb "scripts\update-agent-context.ps1"

try {
  # Invoke a helper as a child process with a localized ErrorActionPreference. A native
  # command's stderr line (PS 5.1 wraps it as NativeCommandError) would otherwise abort
  # this runner under -ErrorActionPreference Stop; under Continue it is harmless and we
  # judge success/failure by the child's exit code, not by $?.
  function Invoke-Ps([string]$CommandLine) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
      $out = & powershell -NoProfile -ExecutionPolicy Bypass -Command $CommandLine 2>$null
      return [pscustomobject]@{ Out = $out; Code = $LASTEXITCODE }
    } finally {
      $ErrorActionPreference = $old
    }
  }
  # Helpers are invoked via -Command (NOT -File) on purpose: under -File, an array arg
  # like -Tech "a","b" arrives as the single literal string "a,b" (the comma is not the
  # PowerShell array operator), which would silently collapse the tech stack to one line.
  # -Command evaluates PowerShell syntax, so -Tech 'a','b' is a real 2-element array.
  # new-feature.ps1 prints the created path on stdout; take the last non-empty line.
  function New-Feat($Name) {
    $safe = $Name -replace "'", "''"
    $r = Invoke-Ps "& '$nfScript' -Name '$safe' -NoBranch"
    return ($r.Out | Where-Object { $_ -ne '' } | Select-Object -Last 1)
  }

  # --- new-feature: slug normalization and sequential numbering ---
  $nfFail = $false
  $p = New-Feat 'User Auth!!'
  if ((Split-Path -Leaf $p) -ne '001-user-auth') { Fail "slug: 'User Auth!!' expected 001-user-auth / got $(Split-Path -Leaf $p)"; $nfFail = $true }
  if (-not (Test-Path (Join-Path $p 'spec.md'))) { Fail "new-feature: spec.md not created"; $nfFail = $true }
  $p = New-Feat '支払い payment flow'
  if ((Split-Path -Leaf $p) -ne '002-payment-flow') { Fail "slug+seq: expected 002-payment-flow / got $(Split-Path -Leaf $p)"; $nfFail = $true }
  $p = New-Feat '  Multiple   Spaces--and__symbols!! '
  if ((Split-Path -Leaf $p) -ne '003-multiple-spaces-and-symbols') { Fail "slug: expected 003-multiple-spaces-and-symbols / got $(Split-Path -Leaf $p)"; $nfFail = $true }
  if (-not $nfFail) { Pass "new-feature: slug normalization & sequential numbering (3 cases)" }

  # A name without ASCII alphanumerics must exit non-zero.
  $r = Invoke-Ps "& '$nfScript' -Name 'あいうえお' -NoBranch"
  if ($r.Code -eq 0) { Fail "new-feature: did not reject a name without ASCII alphanumerics" }
  else { Pass "new-feature: correctly rejects a name without ASCII alphanumerics" }

  # --- update-agent-context: byte-identical to golden ---
  $agents = Join-Path $sb "AGENTS.md"
  Remove-Item $agents -ErrorAction SilentlyContinue
  Invoke-Ps "& '$ucScript' -Feature 001-user-auth -Tech 'Go 1.22','chi v5' -Summary 'user login with JWT'" | Out-Null
  if (Test-ByteEqual "$root\tests\golden\agents-new.md" $agents) { Pass "update-agent-context: new file is byte-identical to golden" }
  else { Fail "update-agent-context: new file differs from golden" }

  Copy-Item "$root\tests\fixtures\agents-seed.md" $agents -Force
  Invoke-Ps "& '$ucScript' -Feature 006-f -Tech 'chi v5','Redis' -Summary 'add feature f'" | Out-Null
  if (Test-ByteEqual "$root\tests\golden\agents-incremental.md" $agents) { Pass "update-agent-context: incremental (dedupe/KEEP/preserve) is byte-identical to golden" }
  else { Fail "update-agent-context: incremental differs from golden" }
}
finally {
  Remove-Item -Recurse -Force $sb -ErrorAction SilentlyContinue
}

Write-Host ""
if ($fail) { Write-Host "Parity test FAILED. See the NG items above."; exit 1 }
Write-Host "All parity tests passed."
exit 0
