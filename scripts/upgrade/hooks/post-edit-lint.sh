#!/usr/bin/env bash
# PostToolUse フック: newapp/ の PHP ファイルが変わったら PHP 8.5 で構文チェックし、文字コードを確認する。
#   問題があれば終了コード 2 で Claude に知らせる。
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$ROOT" || exit 0
input=$(cat)
case "$input" in
  *newapp/*) ;;
  *) exit 0 ;;
esac
files=$( { git diff --name-only -- newapp; git ls-files --others --exclude-standard -- newapp; } \
  | grep -E '\.(php|inc|tpl|phtml)$' | sort -u)
[ -z "$files" ] && exit 0
existing=()
for f in $files; do [ -f "$f" ] && existing+=("$f"); done
[ ${#existing[@]} -eq 0 ] && exit 0
out=$(scripts/upgrade/lint.sh "${existing[@]}" 2>&1)
lint_rc=$?
enc=$(python3 scripts/upgrade/eucjp.py check "${existing[@]}" 2>&1)
enc_rc=$?
if [ $lint_rc -ne 0 ] || [ $enc_rc -ne 0 ]; then
  { echo "newapp の変更に問題があります:"; echo "$out" | grep -v '^OK'; echo "$enc"; } >&2
  exit 2
fi
exit 0
