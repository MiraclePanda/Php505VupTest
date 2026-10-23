#!/usr/bin/env bash
# 移行先（newapp）の検証を一通り行う。検証担当エージェントが使う。
#   1. PHP 8.5 で構文チェック  2. 文字コードの確認  3. 新環境を起動し DB を初期化（＋データ移行）
#   4. 特性テストを実行  5. 応答とエラーログから PHP のエラー・警告を検出
#   6. ゴールデンがあれば比較。なければ旧環境の挙動の推定（tests/characterization/expectations.tsv）と照合し、
#      直前のスナップショットとの差分（このステップで変わったケース）を表示
#
#   usage: scripts/upgrade/verify.sh [label]
#     label: スナップショット名（例: R03）。.work/snapshots/<label>/ に結果を保存する
#   環境変数:
#     NEWAPP=newapp       移行先のルート（アプリは $NEWAPP/app、DB 移行スクリプトは $NEWAPP/db/migrate.php）
#     APP_DIR=$NEWAPP/app テスト対象のアプリ（移行前のアプリを新環境で動かすなら APP_DIR=app）
#     PORT=8085  IMAGE=php505-modern  NAME=php505-verify（コンテナ名）
#     KEEP=1              終わってもコンテナを残す（追加の入力を curl で試すため。片付けは docker rm -f $NAME）
#   終了コード: 0 = 構文・文字コード・PHP エラーなし（かつゴールデンがあれば一致）、1 = 問題あり
. "$(dirname "$0")/env.sh"
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
LABEL=${1:-$(date +%H%M%S)}
NEWAPP=${NEWAPP:-newapp}
APP_DIR=${APP_DIR:-$NEWAPP/app}
PORT=${PORT:-8085}
IMAGE=${IMAGE:-php505-modern}
NAME=${NAME:-php505-verify}
KEEP=${KEEP:-0}
SNAP=.work/snapshots
ACTUAL=tests/characterization/actual
GOLDEN=tests/characterization/golden
fail=0

echo "### 1. 構文チェック（PHP 8.5）"
scripts/upgrade/lint.sh "$APP_DIR" | grep -v '^OK' ; [ "${PIPESTATUS[0]}" -eq 0 ] && { echo "OK"; S_LINT=OK; } || { fail=1; S_LINT=NG; }

echo "### 2. 文字コード（${SRC_ENCODING:-EUC-JP}）"
find "$APP_DIR" -type f \( -name '*.php' -o -name '*.inc' -o -name '*.tpl' -o -name '*.phtml' \) -print0 | xargs -0 python3 scripts/upgrade/eucjp.py check && { echo "OK"; S_ENC=OK; } || { fail=1; S_ENC=NG; }

echo "### 3. 新環境の起動と DB 初期化"
docker image inspect "$IMAGE" >/dev/null 2>&1 || scripts/upgrade/build-modern-image.sh "$IMAGE" >&2 || { echo "イメージを用意できない"; exit 1; }
docker rm -f "$NAME" >/dev/null 2>&1
MOUNTS=(-v "$ROOT/$APP_DIR:/var/www/app:ro" -v "$ROOT/db:/var/www/db:ro")
# 新環境の php.ini はイメージに焼き込まれているが、変更をビルドし直さずに効かせるため上から重ねる（R14）
[ -f docker/modern/php.ini ] && MOUNTS+=(-v "$ROOT/docker/modern/php.ini:/usr/local/etc/php/conf.d/zz-app.ini:ro")
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
nerr=$(echo -n "$errs" | grep -c . ; true)
if [ -z "$errs$logs$leak" ]; then echo "OK"; S_ERR=OK; else
  fail=1; S_ERR="NG（$nerr ケース）"
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
  tests/characterization/compare.sh "$GOLDEN" "$ACTUAL" && S_CMP=OK || { fail=1; S_CMP=NG; }
else
  if [ -f tests/characterization/expectations.tsv ]; then
    echo "- ゴールデンなし（旧環境で未記録）。旧環境の挙動の推定（expectations.tsv）と照合する"
    python3 tests/characterization/check-expectations.py "$ACTUAL" | sed 's/^/  /'
    [ "${PIPESTATUS[0]}" -eq 0 ] && S_CMP=OK || { fail=1; S_CMP=NG; }
  else
    echo "- ゴールデンも期待値（expectations.tsv）もない。PHP エラーの有無しか確かめていない（php-upgrade の手順 1.5 で期待値を作ること）"
  fi
  if [ -n "$prev" ] && [ "$prev" != "$LABEL" ]; then
    changed=$(diff -rq "$SNAP/$prev" "$ACTUAL" | grep '^Files ' | sed -E 's@^Files .*/([^/]+)\.txt and .*@\1@' | tr '\n' ' ')
    added=$(diff -rq "$SNAP/$prev" "$ACTUAL" | grep "^Only in $ACTUAL" | sed -E 's@^Only in [^:]+: ([^ ]+)\.txt$@\1@' | tr '\n' ' ')
    removed=$(diff -rq "$SNAP/$prev" "$ACTUAL" | grep "^Only in $SNAP/$prev" | sed -E 's@^Only in [^:]+: ([^ ]+)\.txt$@\1@' | tr '\n' ' ')
    perr=$(grep -lE '(Warning|Deprecated|Notice|Fatal error|Parse error)(</b>)?:' "$SNAP/$prev"/*.txt 2>/dev/null | wc -l)
    echo "- 直前のスナップショット（$prev）から変わったケース: ${changed:-なし}"
    [ -n "$added" ] && echo "- 追加されたケース: $added"
    [ -n "$removed" ] && echo "- なくなったケース: $removed"
    echo "- PHP エラー表示のあるケース数: $perr → $nerr"
    echo "  詳細: diff -ru $SNAP/$prev $SNAP/$LABEL"
  fi
fi
echo "- スナップショット: $SNAP/$LABEL"
if [ "$KEEP" = 1 ]; then echo "- コンテナを残しています: http://localhost:$PORT/（片付け: docker rm -f $NAME）"; else docker rm -f "$NAME" >/dev/null 2>&1; fi
echo "### 要約: 構文 ${S_LINT:-?} / 文字コード ${S_ENC:-?} / PHP エラー ${S_ERR:-?} / ゴールデン・期待値 ${S_CMP:-未照合}"
[ $fail -eq 0 ] && echo "RESULT: OK" || echo "RESULT: NG"
exit $fail
