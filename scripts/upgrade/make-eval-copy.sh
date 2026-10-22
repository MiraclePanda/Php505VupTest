#!/usr/bin/env bash
# 移行パイプラインの評価用に、答えが見えない複製を作る（git 履歴も持たない）。
#   - newapp/（前回の移行結果）、解答キー、振り返りの採点表（knowledge/runs/）、
#     特性テストの期待値（expectations.tsv）を取り除く
#   - 特性テストは移行前の状態（BASE_TESTS_REV の run.sh）に戻す。ケースの追加も評価対象にするため
#   - ルールカタログと knowledge/lessons.md（蓄積したノウハウ）は残す
#   usage: scripts/upgrade/make-eval-copy.sh <dest_dir> [BASE_TESTS_REV=0530fb6]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DEST=${1:?usage: $0 <dest_dir> [base_tests_rev]}
BASE_TESTS_REV=${2:-0530fb6}
[ -e "$DEST" ] && { echo "$DEST は既にあります" >&2; exit 1; }
mkdir -p "$DEST"
git -C "$ROOT" archive HEAD | tar -x -C "$DEST"
cd "$DEST"
rm -rf newapp eval docs/sample-app-traps.md tests/characterization/expectations.tsv
find .claude/skills/php-upgrade/knowledge/runs -type f ! -name .gitkeep -delete
git -C "$ROOT" show "$BASE_TESTS_REV:tests/characterization/run.sh" > tests/characterization/run.sh
chmod +x tests/characterization/run.sh scripts/upgrade/*.sh scripts/upgrade/*.py scripts/upgrade/hooks/* tests/characterization/*.sh tests/characterization/*.py 2>/dev/null || true
# 文書中の解答キーへの言及は残るが、ファイル自体はない
git init -q && git add -A && git -c user.email=eval@example.invalid -c user.name=eval commit -qm "評価用の複製（$(git -C "$ROOT" rev-parse --short HEAD) から作成）"
echo "評価用の複製: $DEST"
