#!/usr/bin/env bash
# 次の連番を採番し specs/NNN-feature-name/ を作成して、そのパスを標準出力に返す。
# 使い方: scripts/new-feature.sh "<機能名>"
#   機能名は自由記述でよい。英数字以外はハイフンに正規化される。
set -euo pipefail

name="${1:-}"
if [ -z "$name" ]; then
  echo "usage: new-feature.sh <feature-name>" >&2
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

dir="$specs/$next-$slug"
mkdir -p "$dir"

# 作成したディレクトリの絶対パスを返す（呼び出し元/エージェントが利用する）
printf '%s\n' "$dir"
