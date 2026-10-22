#!/usr/bin/env bash
# 特性テスト（ゴールデンマスター方式）
#   旧環境の応答をゴールデンとして記録し、移行後の応答と比較する。
#
#   usage: tests/characterization/run.sh <base_url> <out_dir>
#     例) 旧環境で記録: run.sh http://localhost:8050 tests/characterization/golden
#         新環境で取得: run.sh http://localhost:8085 tests/characterization/actual
#   実行前に scripts/reset-db.sh で DB を初期化すること（更新ケースを含むため）。
set -euo pipefail
BASE_URL=${1:?usage: $0 <base_url> <out_dir>}
OUT=${2:?usage: $0 <base_url> <out_dir>}
mkdir -p "$OUT"
rm -f "$OUT"/*.txt
JAR=$(mktemp)
trap 'rm -f "$JAR"' EXIT

# 環境差で揺れる部分を落として比較可能にする
#   残すヘッダ: ステータス行, Location, Content-Type
normalize() {
  tr -d '\r' \
  | awk 'BEGIN { body = 0 }
         body { print; next }
         /^$/ { body = 1; print; next }
         /^HTTP\// || tolower($0) ~ /^(location|content-type):/ { print }' \
  | sed -E -e 's/[[:space:]]+$//' -e 's/PHPSESSID=[A-Za-z0-9,-]+/PHPSESSID=XXX/g' \
  | cat -s
}

# req <ケース名> <パス> [curl の追加引数...]
req() {
  local name=$1 path=$2; shift 2
  curl -sS -i -b "$JAR" -c "$JAR" "$@" "$BASE_URL$path" | normalize > "$OUT/$name.txt"
  echo "  $name: $(head -1 "$OUT/$name.txt")"
}

echo "== $BASE_URL -> $OUT"
# --- 検索（未ログイン）
req 01_search_top            /index.php
req 02_search_keyword        /index.php -G --data-urlencode "keyword=ボールペン"
req 03_search_zenkaku_space  /index.php -G --data-urlencode "keyword=ノート　B5"
req 04_search_category       /index.php -G --data-urlencode "keyword=" --data-urlencode "category=2"
req 05_search_category_all   /index.php -G --data-urlencode "keyword=" --data-urlencode "category="
req 06_search_page2          /index.php -G --data-urlencode "keyword=" --data-urlencode "category=" --data-urlencode "page=2"
req 07_search_page_invalid   /index.php -G --data-urlencode "page=abc"
req 08_search_noresult       /index.php -G --data-urlencode "keyword=存在しない商品"
req 09_search_quote          /index.php -G --data-urlencode "keyword=Let's"
req 10_search_html_chars     /index.php -G --data-urlencode "keyword=<特選>"
# --- ログイン
req 11_edit_without_login    "/edit.php?id=1"
req 12_login_form            /login.php
req 13_login_fail            /login.php --data-urlencode "login_id=admin" --data-urlencode "password=wrong"
req 14_login_ok              /login.php --data-urlencode "login_id=admin" --data-urlencode "password=admin123"
req 15_search_logged_in      /index.php
# --- 編集・更新
req 16_edit_view             "/edit.php?id=10"
req 17_edit_not_found        "/edit.php?id=999"
req 18_update_invalid        "/edit.php?id=10" \
      --data-urlencode "code=bk-1" --data-urlencode "name=O'Reilly 本" \
      --data-urlencode "category_id=9" --data-urlencode "price=abc" --data-urlencode "stock="
req 19_update_ok             "/edit.php?id=10" \
      --data-urlencode "code=BK-0001" --data-urlencode "name=Let's 英会話 入門 改訂版" \
      --data-urlencode "category_id=4" --data-urlencode "price=1980" --data-urlencode "stock=20"
req 20_search_after_update   /index.php -G --data-urlencode "keyword=英会話" --data-urlencode "msg=updated"
# --- ログアウト
req 21_logout                /logout.php
req 22_search_after_logout   /index.php
echo "done: $(ls "$OUT" | wc -l) cases"
