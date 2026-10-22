#!/usr/bin/env bash
# ゴールデンと実測の差分を表示する。差分がなければ終了コード 0。
#   usage: tests/characterization/compare.sh [golden_dir] [actual_dir]
set -uo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
GOLDEN=${1:-$DIR/golden}
ACTUAL=${2:-$DIR/actual}
if diff -ru -x .gitkeep "$GOLDEN" "$ACTUAL"; then
  echo "OK: すべてのケースがゴールデンと一致"
else
  echo "NG: 差分あり（意図した変更なら docs/known-differences.md に記録すること）"
  exit 1
fi
