#!/usr/bin/env bash
# 棚卸しの機械検出をまとめて実行し、Markdown で出力する（棚卸し担当が inventory.md を書く材料）。
#   usage: scripts/upgrade/inventory.sh [src_dir] [legacy_php_ini]
#     既定: app docker/legacy/php.ini
. "$(dirname "$0")/env.sh"
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
SRC=${1:-app}
INI=${2:-docker/legacy/php.ini}
IMAGE=${PHP85_IMAGE:-php:8.5-cli}

echo "# 機械検出結果: $SRC"
echo
echo "生成: $(date '+%Y-%m-%d %H:%M') / scripts/upgrade/inventory.sh"
echo
echo "## 旧環境の実行設定（$INI）"
echo
if [ -f "$INI" ]; then
  echo '```ini'
  grep -E '^\s*(short_open_tag|register_globals|register_long_arrays|magic_quotes_\w+|allow_call_time_pass_reference|error_reporting|display_errors|default_charset|variables_order|output_buffering|mbstring\.\w+|session\.\w+|date\.timezone)\s*=' "$INI"
  echo '```'
else
  echo "（php.ini がない。当時の既定値を仮定し、その旨を inventory.md に書くこと）"
fi
echo
echo "## 文字コード（推定）"
echo
echo "- 移行元: $(python3 scripts/upgrade/eucjp.py detect "$SRC" | sed -n 's/^結論: //p')（道具の設定 SRC_ENCODING=${SRC_ENCODING}）"
[ -d db/init ] && echo "- DB 初期データ（db/init）: $(python3 scripts/upgrade/eucjp.py detect db/init | sed -n 's/^結論: //p')"
echo "- 食い違う場合は .upgrade.env を直してから続けること。php.ini の default_charset / mbstring と HTML の meta charset も確認する"
echo
echo "## ソースの外の前提（R14 の材料）"
echo
echo "以下は機械的に集めた手がかり。実案件ではサーバーの設定（crontab、Apache、odbc.ini、環境変数）を別途取り寄せること。"
echo
for f in docker/legacy/Dockerfile docker/legacy/*.conf docker/legacy/start.sh; do
  [ -f "$f" ] || continue
  echo "### \`$f\`"
  echo '```'
  grep -nE 'ENV |TZ|odbc|ODBC|DSN|Driver|configure|--with|--enable|Alias|Directory|AllowOverride|AddType|php_(value|flag)|cron|LANG|LC_' "$f" | head -40
  echo '```'
done
hits=$(grep -rnE '\b(getenv|putenv|setlocale|date_default_timezone|ini_set|ini_get|set_time_limit|ignore_user_abort|exec|system|passthru|shell_exec|popen|proc_open|mail|fsockopen|odbc_connect|odbc_pconnect|mysql_p?connect|pg_p?connect)\s*\(|\$_ENV|\$HTTP_ENV_VARS|`' "$SRC" 2>/dev/null | head -40)
echo "### ソース中の環境依存の呼び出し"
echo '```'
echo "${hits:-（なし）}" | iconv -f "${SRC_ENCODING}" -t UTF-8 -c
echo '```'
find "$SRC" -name '.htaccess' -o -name '*.sh' -o -name 'crontab*' | sed 's/^/- 設定・スクリプト: /'
echo
echo "## ファイル一覧"
echo
find "$SRC" -type f | sort | while read -r f; do
  enc=$(python3 scripts/upgrade/eucjp.py check "$f" >/dev/null 2>&1 && echo "${SRC_ENCODING:-EUC-JP}" || echo "要確認")
  echo "- \`$f\` ($(wc -l < "$f") 行, $enc)"
done
echo
echo "## PHP 8.5 構文チェック（php -l）"
echo
echo '```'
scripts/upgrade/lint.sh "$SRC" 2>&1 | grep -v '^OK'
echo '```'
echo "（OK のファイルは省略。短縮タグのファイルは php -l を素通りするので R01 を見ること）"
echo
echo "## register_globals 依存の候補（tools/globals-scan.php）"
echo
echo "| ファイル | 行 | 変数 | 種別 |"
echo "|---|---|---|---|"
docker run --rm -v "$ROOT:/src" -w /src "$IMAGE" php -d short_open_tag=1 scripts/upgrade/tools/globals-scan.php "$SRC" \
  | awk -F'\t' '{ printf "| `%s` | %s | `%s` | %s |\n", $1, $2, $3, $4 }'
echo
echo "# ルール別の検出候補（scan.py）"
echo
python3 scripts/upgrade/scan.py "$SRC"
