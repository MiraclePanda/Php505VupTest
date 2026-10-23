#!/usr/bin/env bash
# 移行パイプラインの評価用に、答えが見えない複製を作る（git 履歴も持たない）。
#   - newapp/（前回の移行結果）、解答キー、振り返りの採点表（knowledge/runs/）、
#     特性テストの期待値（expectations.tsv）を取り除く
#   - 特性テストは移行前の状態（BASE_TESTS_REV の run.sh）に戻す。ケースの追加も評価対象にするため
#   - ルールカタログと knowledge/lessons.md（蓄積したノウハウ）は残す
#   --app <dir>: 別のサンプルアプリ（eval/apps/app2 など）で評価する。app/、db/init/、旧環境の php.ini、
#                特性テスト（<dir>/run.sh）を差し替え、.upgrade.env を消す（文字コードの判定も評価対象）
#   usage: scripts/upgrade/make-eval-copy.sh <dest_dir> [--app eval/apps/app2] [BASE_TESTS_REV=0530fb6]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DEST=${1:?usage: $0 <dest_dir> [--app dir] [base_tests_rev]}
shift
APP=""
if [ "${1:-}" = "--app" ]; then APP=$(cd "$ROOT" && realpath "$2"); shift 2; fi
BASE_TESTS_REV=${1:-0530fb6}
[ -e "$DEST" ] && { echo "$DEST は既にあります" >&2; exit 1; }
mkdir -p "$DEST"
git -C "$ROOT" archive HEAD | tar -x -C "$DEST"
cd "$DEST"
rm -rf newapp eval docs/sample-app-traps.md tests/characterization/expectations.tsv
find .claude/skills/php-upgrade/knowledge/runs -type f ! -name .gitkeep -delete
if [ -n "$APP" ]; then
  rm -rf app db/init .upgrade.env tests/characterization/golden/*
  cp -a "$APP/app" app
  cp -a "$APP/db/init" db/init
  cp "$APP/legacy-php.ini" docker/legacy/php.ini
  cp "$APP/run.sh" tests/characterization/run.sh
  # 文書に残る前のサンプル固有の記述（文字コード）を外す
  sed -i 's/このサンプルは EUC-JP。//' CLAUDE.md
else
  git -C "$ROOT" show "$BASE_TESTS_REV:tests/characterization/run.sh" > tests/characterization/run.sh
fi
chmod +x tests/characterization/run.sh scripts/upgrade/*.sh scripts/upgrade/*.py scripts/upgrade/hooks/* tests/characterization/*.sh tests/characterization/*.py 2>/dev/null || true
# 文書中の解答キーへの言及は残るが、ファイル自体はない
git init -q && git add -A && git -c user.email=eval@example.invalid -c user.name=eval commit -qm "評価用の複製（$(git -C "$ROOT" rev-parse --short HEAD) から作成）"
echo "評価用の複製: $DEST${APP:+（アプリ: $APP）}"
