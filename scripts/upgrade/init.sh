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
# 移行元の文字コードを推定し、.upgrade.env がなければ書く（eucjp.py などの道具はこれを読む）
enc=$(python3 scripts/upgrade/eucjp.py detect "$SRC" | sed -n 's/^結論: //p')
echo "移行元の文字コード（推定）: $enc"
if [ ! -f .upgrade.env ]; then
  case "$enc" in
    EUC-JP|CP932|UTF-8) echo "SRC_ENCODING=$enc" > .upgrade.env; echo ".upgrade.env を作成: SRC_ENCODING=$enc" ;;
    *) echo "文字コードを 1 つに決められない（$enc）。.upgrade.env に SRC_ENCODING=... を手で書くこと" >&2 ;;
  esac
elif ! grep -q "SRC_ENCODING=$enc\b" .upgrade.env; then
  echo "注意: .upgrade.env の SRC_ENCODING と推定（$enc）が食い違う。確認すること" >&2
fi
mkdir -p "$DEST/docs" "$DEST/db"
cp -a "$SRC" "$DEST/app"
TPL=.claude/skills/php-upgrade/templates
for f in inventory.md diff-classification.md migration-report.md; do
  [ -e "$DEST/docs/$f" ] || cp "$TPL/$f" "$DEST/docs/$f"
done
echo "初期化しました: $DEST/app（$SRC の複写）"
echo "テンプレートを置きました: $DEST/docs/{inventory,diff-classification,migration-report}.md（Write で上書きする前に Read すること）"
diff -r "$SRC" "$DEST/app" && echo "移行元と一致"
