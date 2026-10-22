#!/usr/bin/env bash
# 特性テスト（ゴールデンマスター方式）
#   旧環境の応答をゴールデンとして記録し、移行後の応答と比較する。
#
#   usage: tests/characterization/run.sh <base_url> <out_dir>
#     例) 旧環境で記録: run.sh http://localhost:8050 tests/characterization/golden
#         新環境で取得: run.sh http://localhost:8085 tests/characterization/actual
#   実行前に scripts/reset-db.sh で DB を初期化すること（更新ケースを含むため）。
#   出力は EUC-JP のバイト列のまま保存する（文字コードも比較対象）。
set -euo pipefail
export LC_ALL=C
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

# 日本語のパラメータはアプリの文字コード（.upgrade.env の SRC_ENCODING。既定 EUC-JP）にして送る
. "$(dirname "$0")/../../scripts/upgrade/env.sh"
e() { printf '%s' "$1" | iconv -f UTF-8 -t "$SRC_ENCODING"; }

# req <ケース名> <パス> [curl の追加引数...]
req() {
  local name=$1 path=$2; shift 2
  curl -sS -i -b "$JAR" -c "$JAR" "$@" "$BASE_URL$path" | normalize > "$OUT/$name.txt"
  echo "  $name: $(head -1 "$OUT/$name.txt")"
}
# --- 一覧
req 01_list_top          /index.php
req 02_list_page2        "/index.php?page=2"
# --- 詳細
req 03_view              "/view.php?id=1"
req 04_view_not_found    "/view.php?id=999"
# --- 投稿
req 05_post_form         /post.php
req 06_post_empty        /post.php --data-urlencode "title=" --data-urlencode "body="
req 07_post_ok           /post.php --data-urlencode "title=$(e '備品の発注について')" --data-urlencode "body=$(e '月末までに申請してください。')" --data-urlencode "tags=$(e '総務')"
# --- CSV
req 08_export            /export.php
echo "done: $(ls "$OUT" | wc -l) cases"
