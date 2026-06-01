#!/usr/bin/env bash
# AGENTS.md（全エージェント共有の永続コンテキスト）を増分更新する。
# /plan が plan.md を書いた後に呼ぶ想定。AUTO ブロックのみ機械管理し、
# その外側の手書き分は保持する。技術スタックは重複排除して蓄積し、
# 直近の変更は新しい順に最大 KEEP 件だけ残す。
# 使い方:
#   update-agent-context.sh --feature 003-user-auth \
#     [--tech "Go 1.22"]... [--summary "一行要約"]
# 設計メモ: plan.md の表解析は脆いので、設計者（エージェント）が確定済みの事実を
#           引数で渡す方針。スクリプトは機械的なマージ／保持／トリムだけを担う。
# 注: AGENTS.md の骨格は ASCII 英語で書く。PowerShell 版と出力を一致させ、
#     CP932 起因の文字化けを骨格レベルで避けるため（動的な中身は引数なので何語でも可）。
set -euo pipefail

feature=""; summary=""
techs=()
while [ $# -gt 0 ]; do
  case "$1" in
    --feature) feature="${2:-}"; shift 2 ;;
    --tech)    [ -n "${2:-}" ] && techs+=("$2"); shift 2 ;;
    --summary) summary="${2:-}"; shift 2 ;;
    -h|--help)
      echo "usage: update-agent-context.sh --feature <NNN-slug> [--tech X]... [--summary S]"
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
if [ -z "$feature" ]; then
  echo "usage: update-agent-context.sh --feature <NNN-slug> [--tech X]... [--summary S]" >&2
  exit 1
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
file="$root/AGENTS.md"
keep=5

mark_begin='<!-- AUTO:BEGIN (managed by scripts/update-agent-context; manual edits here are overwritten) -->'
mark_end='<!-- AUTO:END -->'

default_head() {
  cat <<'EOF'
# AGENTS.md - Project context (shared memory for AI agents)

<!-- All agents (Claude / Cursor / Copilot / Gemini, etc.) read this persistent
     context. The AUTO block below is maintained by scripts/update-agent-context
     on every /plan. Anything OUTSIDE the AUTO markers is yours to edit by hand
     and is preserved across updates. -->
EOF
}

# --- 既存ファイルを head / auto-body / tail に切り分ける ---
head_lines=(); tail_lines=(); auto_lines=()
have_block=0
if [ -f "$file" ]; then
  mapfile -t all < "$file"
  bi=-1; ei=-1
  for i in "${!all[@]}"; do
    if [ "$bi" -lt 0 ]; then
      case "${all[$i]}" in "<!-- AUTO:BEGIN"*) bi=$i ;; esac
    fi
    case "${all[$i]}" in "<!-- AUTO:END -->"*) ei=$i ;; esac
  done
  if [ "$bi" -ge 0 ] && [ "$ei" -gt "$bi" ]; then
    have_block=1
    [ "$bi" -gt 0 ] && head_lines=( "${all[@]:0:bi}" )
    [ "$((ei - bi - 1))" -gt 0 ] && auto_lines=( "${all[@]:bi+1:ei-bi-1}" )
    [ "$((ei + 1))" -lt "${#all[@]}" ] && tail_lines=( "${all[@]:ei+1}" )
  else
    # ブロックの無い既存ファイル: 全文を head として温存し、末尾に新ブロックを足す。
    [ "${#all[@]}" -gt 0 ] && head_lines=( "${all[@]}" )
  fi
fi

# --- 既存の AUTO ブロックから技術スタック／直近変更を読み取る ---
section=""
existing_tech=(); existing_recent=()
if [ "${#auto_lines[@]}" -gt 0 ]; then
  for ln in "${auto_lines[@]}"; do
    case "$ln" in
      "## Active tech stack"*) section="tech"; continue ;;
      "## Recent changes"*)    section="recent"; continue ;;
      "## "*)                  section=""; continue ;;
    esac
    case "$ln" in
      "- (none yet)") continue ;;
      "- "*)
        if [ "$section" = "tech" ]; then existing_tech+=("${ln#- }")
        elif [ "$section" = "recent" ]; then existing_recent+=("$ln"); fi
        ;;
    esac
  done
fi

# --- 技術スタックをマージ（順序を保ったまま重複排除） ---
merged_tech=()
[ "${#existing_tech[@]}" -gt 0 ] && merged_tech=( "${existing_tech[@]}" )
if [ "${#techs[@]}" -gt 0 ]; then
  for t in "${techs[@]}"; do
    found=0
    if [ "${#merged_tech[@]}" -gt 0 ]; then
      for x in "${merged_tech[@]}"; do [ "$x" = "$t" ] && { found=1; break; }; done
    fi
    [ "$found" -eq 0 ] && merged_tech+=("$t")
  done
fi

# --- 直近変更: 同一機能の旧エントリを除き、新しい順で先頭に積み、KEEP 件に切る ---
new_recent="- $feature"
[ -n "$summary" ] && new_recent="- $feature: $summary"
filtered=()
if [ "${#existing_recent[@]}" -gt 0 ]; then
  for ln in "${existing_recent[@]}"; do
    case "$ln" in
      "- $feature"|"- $feature:"*) continue ;;
      *) filtered+=("$ln") ;;
    esac
  done
fi
recent=( "$new_recent" )
[ "${#filtered[@]}" -gt 0 ] && recent+=( "${filtered[@]}" )
[ "${#recent[@]}" -gt "$keep" ] && recent=( "${recent[@]:0:keep}" )

# --- AUTO ブロックを再構築する ---
render_block() {
  echo "$mark_begin"
  echo "## Active tech stack"
  echo ""
  if [ "${#merged_tech[@]}" -gt 0 ]; then
    for t in "${merged_tech[@]}"; do echo "- $t"; done
  else
    echo "- (none yet)"
  fi
  echo ""
  echo "## Recent changes"
  echo ""
  for ln in "${recent[@]}"; do echo "$ln"; done
  echo "$mark_end"
}

# --- 書き出し（head + 新ブロック + tail）。一時ファイル経由で原子的に置換 ---
tmp="$file.tmp.$$"
{
  if [ "$have_block" -eq 1 ]; then
    [ "${#head_lines[@]}" -gt 0 ] && printf '%s\n' "${head_lines[@]}"
  elif [ -f "$file" ]; then
    printf '%s\n' "${head_lines[@]}"
    echo ""   # 既存の手書き本文と、新たに足すブロックの間に空行を入れる
  else
    default_head   # 新規ファイル
    echo ""
  fi
  render_block
  [ "${#tail_lines[@]}" -gt 0 ] && printf '%s\n' "${tail_lines[@]}"
} > "$tmp"
mv "$tmp" "$file"

# 確認メッセージは stderr へ（stdout は静かに保つ）。
echo "AGENTS.md updated (feature: $feature; tech entries: ${#merged_tech[@]})" >&2
