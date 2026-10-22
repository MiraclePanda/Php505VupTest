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
e() { printf '%s' "$1" | iconv -f UTF-8 -t CP932; }  # 隠しテストは移行元の文字コードに固定

# req <ケース名> <パス> [curl の追加引数...]
req() {
  local name=$1 path=$2; shift 2
  curl -sS -i -b "$JAR" -c "$JAR" "$@" "$BASE_URL$path" | normalize > "$OUT/$name.txt"
  echo "  $name: $(head -1 "$OUT/$name.txt")"
}
# --- 一覧（読み取りだけ）
req c01_list_top            /index.php
req c02_list_page2          "/index.php?page=2"
req c03_list_sort_title     "/index.php?sort=title"
req c04_search_katakana     /index.php -G --data-urlencode "kw=$(e 'ソフト')"
req c05_search_ascii_t      "/index.php?kw=t"
req c06_search_dquote       /index.php -G --data-urlencode 'kw="X"'
req c07_view_dquote         "/view.php?id=4"
req c08_view_tags_5c        "/view.php?id=3"
req c09_view_not_found      "/view.php?id=999"
req c10_view_ibm_ext1       "/view.php?id=5"
req c11_view_ibm_ext2       "/view.php?id=6"
req c12_view_bad_id         "/view.php?id=abc"
req c13_list_msg_param      /index.php -G --data-urlencode "msg=<b>hi</b>"
req c14_list_page_newline   /index.php -G --data-urlencode $'page=2\n'
req c15_list_kw_array       "/index.php?kw%5B%5D=x"
req c16_export              /export.php
req c17_delete_noauth       "/admin/delete.php?id=2"
# --- 投稿（DB を変える）
req c18_post_form           /post.php
req c19_post_empty          /post.php --data-urlencode "title=" --data-urlencode "body=x"
req c20_post_31chars        /post.php --data-urlencode "title=$(e 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほま')" --data-urlencode "body=x"
req c21_post_30chars        /post.php --data-urlencode "title=$(e 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほ')" --data-urlencode "body=x"
req c22_post_special        /post.php --data-urlencode "title=$(e 'ソフト"テスト"')" --data-urlencode 'body=a\b' --data-urlencode "tags=$(e 'ソフト,テスト')"
req c23_view_posted         "/view.php?id=9"
req c24_search_posted       /index.php -G --data-urlencode "kw=$(e 'テスト')"
req c25_list_after_post     /index.php
req c26_delete_auth         "/admin/delete.php?id=2" -u admin:secret
req c27_list_after_delete   /index.php
echo "done: $(ls "$OUT" | wc -l) cases"
