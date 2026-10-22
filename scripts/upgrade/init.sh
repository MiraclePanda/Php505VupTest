#!/usr/bin/env bash
# 移行先を用意する。移行元をバイト単位でそのまま複写し、作業記録のディレクトリを作る。
#   usage: scripts/upgrade/init.sh [src=app] [dest=newapp]
#   dest/app   移行するアプリ（移行元の複写から始める。以後ここだけを書き換える）
#   dest/db    DB 移行スクリプト（3C）
#   dest/docs  棚卸し、差分の分類案、移行レポート
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
SRC=${1:-app}
DEST=${2:-newapp}
if [ -e "$DEST/app" ]; then
  echo "$DEST/app は既にあります。やり直すなら git rm -r $DEST/app してから実行してください" >&2
  exit 1
fi
mkdir -p "$DEST/docs" "$DEST/db"
cp -a "$SRC" "$DEST/app"
TPL=.claude/skills/php-upgrade/templates
for f in inventory.md diff-classification.md migration-report.md; do
  [ -e "$DEST/docs/$f" ] || cp "$TPL/$f" "$DEST/docs/$f"
done
echo "初期化しました: $DEST/app（$SRC の複写）"
diff -r "$SRC" "$DEST/app" && echo "移行元と一致"
