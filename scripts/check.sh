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

# 各入口が「自分と同名の」prompts/*.md を参照しているか（取り違え検知）。
# 名前集合の一致とリンク切れの両方を通り抜けても、specify の入口が
# 誤って prompts/plan.md を指すような取り違えは沈黙する。それを塞ぐ。
mismatch=0
check_self_ref() {
  local label="$1" dir="$2" suffix="$3"
  for f in "$dir"/*"$suffix"; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"; name="${b%$suffix}"
    grep -qE "prompts/${name}\.md([^a-z]|\$)" "$f" \
      || { err "$label: 入口 $b が自分の prompt（prompts/${name}.md）を参照していない"; mismatch=1; }
  done
}
check_self_ref "claude" ".claude/commands" ".md"
check_self_ref "cursor" ".cursor/commands" ".md"
check_self_ref "github" ".github/prompts"  ".prompt.md"
check_self_ref "gemini" ".gemini/commands" ".toml"
[ "$mismatch" -eq 0 ] && ok "入口は各々自分の prompt を参照している"

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

# テンプレの必須見出し（真実の源）。examples 照合とテンプレ自己整合の双方が、
# この一つの定義を参照する。検査スクリプト内に見出しを二重写ししないための集約点だ。
# 小さな機能が正当に省ける節（tasks のフェーズ等）は必須に含めない。§8/§9 は任意ゆえ別扱い。
spec_heads=("## 1. 概要" "## 2. なぜ" "## 3. ユーザーストーリー" "## 4. スコープ" "## 5. 非機能要件" "## 6. 未決定事項" "## 7. 憲法との整合")
plan_heads=("## 1. 技術スタック" "## 2. アーキテクチャ概要" "## 3. データモデル" "## 4. インターフェース" "## 5. 主要な設計判断" "## 6. Constitution Check" "## 7. リスクと未確定事項")
tasks_heads=("## 凡例" "## トレーサビリティ")
spec_trace_heads=("## 8. 明確化ログ" "## 9. 改訂履歴")

# 自己整合ゲート: check が必須とする見出しは、真実の源であるテンプレに実在するか。
# テンプレが見出しを改名・削除したのに、この check のリストだけ古いまま残る乖離を捕まえる。
# これが無いと「examples が check のリストに従うか」しか見ず、「check がテンプレに従うか」は
# 誰も見ない——鮮度ゲートが自分の鮮度を守れない死角になる。包含照合で括弧書きの揺れを吸収する。
tsync=0
check_template_sync() {
  local template="$1"; shift
  [ -f "$template" ] || { err "テンプレ同期: $template が存在しない"; tsync=1; return; }
  for h in "$@"; do
    grep -qF -- "$h" "$template" \
      || { err "テンプレ同期: $template に必須見出し「$h」が無い（check のリストがテンプレと乖離）"; tsync=1; }
  done
}
check_template_sync "templates/spec-template.md"  "${spec_heads[@]}" "${spec_trace_heads[@]}"
check_template_sync "templates/plan-template.md"  "${plan_heads[@]}"
check_template_sync "templates/tasks-template.md" "${tasks_heads[@]}"
[ "$tsync" -eq 0 ] && ok "check の必須見出しはテンプレと一致している（真実の源との自己整合）"

# examples/ がテンプレの骨格（必須見出し）に追従しているか（教材の鮮度ゲート）。
# examples はドッグフードの教材。テンプレが進化して見出しが変わったのに examples が
# 取り残される乖離を捕まえる。照合の基準は上の真実の源（*_heads）を共用する。
ebroken=0
check_doc() {
  local file="$1"; shift
  [ -f "$file" ] || return 0   # その成果物が無い example はスキップ（plan 未着手など）
  for h in "$@"; do
    grep -qF -- "$h" "$file" || { err "examples 鮮度: $file に見出し「$h」が無い"; ebroken=1; }
  done
}
# clarify/amend を通した example は、痕跡（§8/§9 見出し）と追跡（AC 側の → §8/→ §9 参照）を
# 対で持つこと。片方だけ（見出しはあるが参照が無い／その逆）は教材として片肺だ。
# §8/§9 を持たない example（順調に流れる例）は無風で通る＝library-loan 非依存。
check_trace() {
  local file="$1" heading="$2" ref="$3"
  [ -f "$file" ] || return 0
  local has_h=0 has_r=0
  grep -qF -- "$heading" "$file" && has_h=1
  grep -qF -- "$ref"     "$file" && has_r=1
  if [ "$has_h" -ne "$has_r" ]; then
    err "examples 鮮度: $file は「$heading」と参照「$ref」を対で持つべき（今は片方だけ）"; ebroken=1
  fi
}
for d in examples/*/; do
  check_doc "${d}spec.md"  "${spec_heads[@]}"
  check_doc "${d}plan.md"  "${plan_heads[@]}"
  check_doc "${d}tasks.md" "${tasks_heads[@]}"
  check_trace "${d}spec.md" "${spec_trace_heads[0]}" "→ §8"
  check_trace "${d}spec.md" "${spec_trace_heads[1]}" "→ §9"
done
[ "$ebroken" -eq 0 ] && ok "examples はテンプレの骨格（必須見出し）に追従している"

echo ""
if [ "$fail" -ne 0 ]; then
  echo "検査失敗。上の NG を修正せよ。" >&2
  exit 1
fi
echo "すべての検査を通過した。"
