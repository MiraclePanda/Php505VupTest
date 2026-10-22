#!/usr/bin/env bash
# 移行先（newapp）の検証を一通り行う。検証担当エージェントが使う。
#   1. PHP 8.5 で構文チェック  2. 文字コードの確認  3. 新環境を起動し DB を初期化（＋データ移行）
#   4. 特性テストを実行  5. 応答とエラーログから PHP のエラー・警告を検出
#   6. ゴールデンがあれば比較。なければ直前のスナップショットとの差分（このステップで変わったケース）を表示
#
#   usage: scripts/upgrade/verify.sh [label]
#     label: スナップショット名（例: R03）。.work/snapshots/<label>/ に結果を保存する
#   環境変数:
#     NEWAPP=newapp       移行先のルート（アプリは $NEWAPP/app、DB 移行スクリプトは $NEWAPP/db/migrate.php）
#     APP_DIR=$NEWAPP/app テスト対象のアプリ（移行前のアプリを新環境で動かすなら APP_DIR=app）
#     PORT=8085  IMAGE=php505-modern
#   終了コード: 0 = 構文・文字コード・PHP エラーなし（かつゴールデンがあれば一致）、1 = 問題あり
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
LABEL=${1:-$(date +%H%M%S)}
NEWAPP=${NEWAPP:-newapp}
APP_DIR=${APP_DIR:-$NEWAPP/app}
PORT=${PORT:-8085}
IMAGE=${IMAGE:-php505-modern}
NAME=php505-verify
SNAP=.work/snapshots
ACTUAL=tests/characterization/actual
GOLDEN=tests/characterization/golden
fail=0

echo "### 1. 構文チェック（PHP 8.5）"
scripts/upgrade/lint.sh "$APP_DIR" | grep -v '^OK' ; [ "${PIPESTATUS[0]}" -eq 0 ] && echo "OK" || fail=1

echo "### 2. 文字コード（${SRC_ENCODING:-EUC-JP}）"
find "$APP_DIR" -type f \( -name '*.php' -o -name '*.inc' \) -print0 | xargs -0 python3 scripts/upgrade/eucjp.py check && echo "OK" || fail=1

echo "### 3. 新環境の起動と DB 初期化"
docker image inspect "$IMAGE" >/dev/null 2>&1 || scripts/upgrade/build-modern-image.sh "$IMAGE" >&2 || { echo "イメージを用意できない"; exit 1; }
docker rm -f "$NAME" >/dev/null 2>&1
MOUNTS=(-v "$ROOT/$APP_DIR:/var/www/app:ro" -v "$ROOT/db:/var/www/db:ro")
[ -d "$NEWAPP" ] && MOUNTS+=(-v "$ROOT/$NEWAPP:/var/www/newapp:ro")
# start.sh の自動初期化を避けるため、Apache を直接起動する
docker run -d --name "$NAME" -p "$PORT:80" "${MOUNTS[@]}" "$IMAGE" docker-php-entrypoint apache2-foreground >/dev/null
LEGACY_DSN="Driver=SQLite3;Database=/var/www/data/legacy.db"
db_fail() { echo "DB の初期化・移行に失敗したため中止"; docker rm -f "$NAME" >/dev/null 2>&1; echo "RESULT: NG"; exit 1; }
docker exec "$NAME" php /var/www/db/init.php /var/www/data/legacy.db "$LEGACY_DSN" || db_fail
if [ -f "$NEWAPP/db/migrate.php" ] && [ "$APP_DIR" = "$NEWAPP/app" ]; then
  echo "- データ移行: $NEWAPP/db/migrate.php"
  docker exec "$NAME" php /var/www/newapp/db/migrate.php "$LEGACY_DSN" shop /var/www/data/shop.db || db_fail
else
  echo "- データ移行なし（旧データをそのまま使う）"
  docker exec "$NAME" sh -c 'cp /var/www/data/legacy.db /var/www/data/shop.db && chmod 666 /var/www/data/shop.db'
fi
for i in $(seq 1 20); do curl -s -o /dev/null "http://localhost:$PORT/" && break; sleep 0.5; done

echo "### 4. 特性テスト"
tests/characterization/run.sh "http://localhost:$PORT" "$ACTUAL" >/dev/null || fail=1
echo "$(ls "$ACTUAL"/*.txt | wc -l) ケース実行"

echo "### 5. PHP のエラー・警告"
errs=$(grep -lE '(Warning|Deprecated|Notice|Fatal error|Parse error)(</b>)?:' "$ACTUAL"/*.txt 2>/dev/null)
logs=$(docker logs "$NAME" 2>&1 | grep -E 'PHP (Warning|Deprecated|Notice|Fatal error|Parse error)' | sed -E 's/^.*(PHP (Warning|Deprecated|Notice|Fatal error|Parse error))/\1/; s/\\n.*//' | sort | uniq -c)
leak=$(grep -lE '^\s*(require_once|include|\$\w+ = )' "$ACTUAL"/*.txt 2>/dev/null)
if [ -z "$errs$logs$leak" ]; then echo "OK"; else
  fail=1
  [ -n "$errs" ] && echo "応答にエラー表示: $(echo $errs | xargs -n1 basename | tr '\n' ' ')"
  [ -n "$logs" ] && echo "エラーログ:" && echo "$logs"
  [ -n "$leak" ] && echo "ソースが出力されている疑い（短縮タグ）: $(echo $leak | xargs -n1 basename | tr '\n' ' ')"
fi

echo "### 6. 比較"
mkdir -p "$SNAP"
prev=$(ls -1t "$SNAP" 2>/dev/null | grep -vx "$LABEL" | head -1)
rm -rf "${SNAP:?}/$LABEL" && cp -r "$ACTUAL" "$SNAP/$LABEL"
if ls "$GOLDEN"/*.txt >/dev/null 2>&1; then
  echo "- ゴールデン（旧環境の記録）と比較"
  tests/characterization/compare.sh "$GOLDEN" "$ACTUAL" || fail=1
else
  echo "- ゴールデンなし（旧環境で未記録）。旧環境との一致は確認できない"
  if [ -n "$prev" ] && [ "$prev" != "$LABEL" ]; then
    changed=$(diff -rq "$SNAP/$prev" "$ACTUAL" | sed -E 's@.*/([^/]+)\.txt.*@\1@' | tr '\n' ' ')
    echo "- 直前のスナップショット（$prev）から変わったケース: ${changed:-なし}"
    echo "  詳細: diff -ru $SNAP/$prev $SNAP/$LABEL"
  fi
fi
echo "- スナップショット: $SNAP/$LABEL"
docker rm -f "$NAME" >/dev/null 2>&1
[ $fail -eq 0 ] && echo "RESULT: OK" || echo "RESULT: NG"
exit $fail
