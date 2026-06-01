#!/usr/bin/env bash
# 次の連番を採番し specs/NNN-feature-name/ を作成して、そのパスを標準出力に返す。
# 併せて templates/spec-template.md を spec.md としてコピーし、執筆の土台を用意する。
# 既定では機能ごとの Git ブランチ NNN-feature-name を切って checkout する
# （1機能=1ブランチ=PR の連結のため）。--no-branch で抑止できる。
# 使い方: scripts/new-feature.sh [--no-branch] "<機能名>"
#   機能名は自由記述でよい。英数字以外はハイフンに正規化される。
set -euo pipefail

name=""
make_branch=1
for arg in "$@"; do
  case "$arg" in
    --no-branch) make_branch=0 ;;
    -*) echo "unknown option: $arg" >&2; exit 1 ;;
    *)
      if [ -z "$name" ]; then name="$arg"
      else echo "error: too many arguments: '$arg'" >&2; exit 1; fi
      ;;
  esac
done
if [ -z "$name" ]; then
  echo "usage: new-feature.sh [--no-branch] <feature-name>" >&2
  exit 1
fi

# ディレクトリ識別子は移植性のため ASCII ケバブケースに正規化する。
# （日本語などの正式名称は spec.md 内のタイトルに残す方針。）
slug="$(printf '%s' "$name" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
if [ -z "$slug" ]; then
  echo "error: 機能名に英数字が含まれていない: '$name'" >&2
  echo "       英数字のケバブケース名を指定せよ（例: user-auth）。" >&2
  exit 1
fi

# リポジトリルート（このスクリプトの一つ上）基準で specs/ を解決
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
specs="$root/specs"
mkdir -p "$specs"

# 既存ディレクトリ名の先頭数値の最大を求め、+1 を3桁ゼロ詰めにする
max=0
for d in "$specs"/*/; do
  [ -d "$d" ] || continue
  base="$(basename "$d")"
  num="${base%%-*}"
  case "$num" in
    ''|*[!0-9]*) continue ;;
  esac
  n=$((10#$num))
  [ "$n" -gt "$max" ] && max="$n"
done
next="$(printf '%03d' $((max + 1)))"

# 機能ごとの Git ブランチ NNN-feature-name へ移る（ディレクトリ作成の前に切り、
# spec.md を最初から機能ブランチ上で生ませる）。best-effort——失敗しても採番は続行。
# stdout はパス専用なので、ここでの報告は全て stderr に出す。
branch="$next-$slug"
if [ "$make_branch" -eq 1 ]; then
  if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$root" show-ref --verify --quiet "refs/heads/$branch"; then
      # 既存ブランチ: 作り直さず切り替えるだけ（再実行に冪等）。
      if git -C "$root" switch "$branch" >/dev/null 2>&1 \
         || git -C "$root" checkout "$branch" >/dev/null 2>&1; then
        echo "branch: switched to existing '$branch'" >&2
      else
        echo "warning: could not switch to existing branch '$branch'; staying put" >&2
      fi
    else
      # 新規ブランチを現在の HEAD から切って移る（switch は新しめの git、checkout は後方互換）。
      if git -C "$root" switch -c "$branch" >/dev/null 2>&1 \
         || git -C "$root" checkout -b "$branch" >/dev/null 2>&1; then
        echo "branch: created and switched to '$branch'" >&2
      else
        echo "warning: could not create branch '$branch'; staying on current branch" >&2
      fi
    fi
  else
    echo "note: not a git repository; skipped branch creation" >&2
  fi
fi

dir="$specs/$next-$slug"
mkdir -p "$dir"

# spec.md の土台を用意する（テンプレがあり、まだ無い場合のみ）。
# stdout はパス専用なので、ここでは何も出力しない（コピーは静かな副作用）。
template="$root/templates/spec-template.md"
if [ -f "$template" ] && [ ! -f "$dir/spec.md" ]; then
  cp "$template" "$dir/spec.md"
fi

# 作成したディレクトリの絶対パスを返す（呼び出し元/エージェントが利用する）
printf '%s\n' "$dir"
