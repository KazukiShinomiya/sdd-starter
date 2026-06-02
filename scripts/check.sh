#!/usr/bin/env bash
# テンプレートの構造的整合性を検査する（ゼロ依存・読み取り専用）。
# CI でも手元でも使う。問題があれば NG を列挙して非ゼロ終了する。
#   - 4エージェントの入口が prompts/ と過不足なく対応しているか
#   - 入口 → prompts/ のリンク切れが無いか
#   - *-template.md への参照のリンク切れが無いか
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fail=0
err() { echo "NG: $*" >&2; fail=1; }
ok()  { echo "OK: $*"; }

# 正準のコマンド集合 = prompts/*.md のベース名
cmds="$(for f in prompts/*.md; do basename "$f" .md; done | sort)"
n="$(echo "$cmds" | wc -w)"

# 各エージェント入口が、コマンド集合と過不足なく一致するか
check_agent() {
  local label="$1" dir="$2" suffix="$3"
  local present
  present="$(for f in "$dir"/*"$suffix"; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"; echo "${b%$suffix}"
  done | sort)"
  if [ "$present" = "$cmds" ]; then
    ok "$label: 全コマンド一致（$n 本）"
  else
    err "$label: コマンド集合が prompts/ と不一致"
    echo "    prompts のみに存在:"; comm -23 <(echo "$cmds") <(echo "$present") | sed 's/^/      /'
    echo "    入口のみに存在:";     comm -13 <(echo "$cmds") <(echo "$present") | sed 's/^/      /'
  fi
}
check_agent "claude" ".claude/commands" ".md"
check_agent "cursor" ".cursor/commands" ".md"
check_agent "github" ".github/prompts"  ".prompt.md"
check_agent "gemini" ".gemini/commands" ".toml"

# 入口が参照する prompts/*.md が実在するか（リンク切れ検査）
broken=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  [ -f "$ref" ] || { err "リンク切れ: 入口が存在しない $ref を参照している"; broken=1; }
done < <(grep -rhoE "prompts/[a-z]+\.md" .claude .cursor .github .gemini | sort -u)
[ "$broken" -eq 0 ] && ok "入口 → prompts のリンク切れなし"

# *-template.md への参照が実在するか
tbroken=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  [ -f "templates/$ref" ] || { err "リンク切れ: 存在しない templates/$ref を参照している"; tbroken=1; }
done < <(grep -rhoE "[a-z-]+-template\.md" prompts templates README.md | sort -u)
[ "$tbroken" -eq 0 ] && ok "テンプレ参照のリンク切れなし"

# 各 prompts/*.md が必須4節を備えるか（骨格の構造ゲート）。
# prompts/ は真実の源なので、節の欠落は全エージェントに波及する。
# 「次の一手」は終端コマンドでは省ける任意節なので検査しない。
pbroken=0
for f in prompts/*.md; do
  [ -e "$f" ] || continue
  for sec in "## 入力" "## 手順" "## 出力" "## 禁止"; do
    grep -qE "^$sec\$" "$f" || { err "prompts 構造: $(basename "$f") に節「$sec」が無い"; pbroken=1; }
  done
done
[ "$pbroken" -eq 0 ] && ok "prompts: 全 prompt が必須4節（入力/手順/出力/禁止）を備える"

echo ""
if [ "$fail" -ne 0 ]; then
  echo "検査失敗。上の NG を修正せよ。" >&2
  exit 1
fi
echo "すべての検査を通過した。"
