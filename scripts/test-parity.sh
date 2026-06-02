#!/usr/bin/env bash
# bash 版ヘルパの振る舞いを golden に対して検証する（パリティテスト・ゼロ依存）。
#   - new-feature.sh         : slug 正規化と連番採番
#   - update-agent-context.sh: AGENTS.md 生成（重複排除 / KEEP トリム / 手書き保持）
# PowerShell 版 (test-parity.ps1) は同じ tests/golden・tests/fixtures を使う。
# 両系統が同一 golden を byte 一致で通れば、bash/PS の振る舞い等価性が担保される
# （= 片方だけ直して片方を忘れる乖離を機械が捕まえる）。
# 隔離: temp に scripts/ と templates/ を複製して実行し、実 specs/ や AGENTS.md を汚さない。
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
err() { echo "NG: $*" >&2; fail=1; }
ok()  { echo "OK: $*"; }

sb="$(mktemp -d)"
trap 'rm -rf "$sb"' EXIT
mkdir -p "$sb/scripts" "$sb/templates"
cp "$root/scripts/new-feature.sh"          "$sb/scripts/"
cp "$root/scripts/update-agent-context.sh" "$sb/scripts/"
cp "$root/templates/spec-template.md"      "$sb/templates/"

nf() { bash "$sb/scripts/new-feature.sh" "$@"; }

# --- new-feature: slug 正規化と連番採番 ---
nf_fail=0
out="$(nf --no-branch 'User Auth!!')"
[ "$(basename "$out")" = "001-user-auth" ] || { err "slug: 'User Auth!!' 期待 001-user-auth / 実際 $(basename "$out")"; nf_fail=1; }
[ -f "$out/spec.md" ] || { err "new-feature: spec.md が生成されない"; nf_fail=1; }
out="$(nf --no-branch '支払い payment flow')"
[ "$(basename "$out")" = "002-payment-flow" ] || { err "slug+連番: 日本語混じり 期待 002-payment-flow / 実際 $(basename "$out")"; nf_fail=1; }
out="$(nf --no-branch '  Multiple   Spaces--and__symbols!! ')"
[ "$(basename "$out")" = "003-multiple-spaces-and-symbols" ] || { err "slug: 記号/空白 期待 003-multiple-spaces-and-symbols / 実際 $(basename "$out")"; nf_fail=1; }
[ "$nf_fail" -eq 0 ] && ok "new-feature: slug 正規化・連番採番（3 ケース）"

# 英数字を含まない名前は失敗終了すべき
if nf --no-branch 'あいうえお' >/dev/null 2>&1; then
  err "new-feature: 英数字なしの入力を拒否しなかった"
else
  ok "new-feature: 英数字なしの入力を正しく拒否"
fi

# --- update-agent-context: golden と byte 一致 ---
cmp_golden() {
  local label="$1" golden="$2" actual="$3"
  if cmp -s "$golden" "$actual"; then
    ok "update-agent-context: $label が golden と byte 一致"
  else
    err "update-agent-context: $label が golden と不一致"
    diff -u "$golden" "$actual" >&2 || true
  fi
}
rm -f "$sb/AGENTS.md"
bash "$sb/scripts/update-agent-context.sh" --feature 001-user-auth --tech "Go 1.22" --tech "chi v5" --summary "user login with JWT" 2>/dev/null
cmp_golden "新規生成" "$root/tests/golden/agents-new.md" "$sb/AGENTS.md"

cp "$root/tests/fixtures/agents-seed.md" "$sb/AGENTS.md"
bash "$sb/scripts/update-agent-context.sh" --feature 006-f --tech "chi v5" --tech "Redis" --summary "add feature f" 2>/dev/null
cmp_golden "増分（重複排除/KEEP/手書き保持）" "$root/tests/golden/agents-incremental.md" "$sb/AGENTS.md"

echo ""
if [ "$fail" -ne 0 ]; then echo "パリティテスト失敗。上の NG を確認せよ。" >&2; exit 1; fi
echo "パリティテスト全通過。"
