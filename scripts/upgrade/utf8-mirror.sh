#!/usr/bin/env bash
# EUC-JP のソースを UTF-8 にした読み取り用の写しを .work/utf8/ に作る（Read ツールで読むため）。
#   エージェントが iconv などの読み取りコマンドを 1 ファイルずつ実行すると、そのたびに許可の確認が出て止まる。
#   最初と、変更のあとに 1 回ずつこれを実行し、以後は .work/utf8/<元のパス> を Read で読む。
#   写しは読み取り専用。書き換えは必ず scripts/upgrade/eucjp.py で元のファイルに対して行う。
#   usage: scripts/upgrade/utf8-mirror.sh [dir...]   （既定: app newapp/app db/init）
. "$(dirname "$0")/env.sh"
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
[ $# -eq 0 ] && set -- app newapp/app db/init
n=0
for d in "$@"; do
  [ -d "$d" ] || continue
  rm -rf ".work/utf8/$d"   # 消えたファイルの写しを残さない
  while IFS= read -r f; do
    mkdir -p ".work/utf8/$(dirname "$f")"
    python3 scripts/upgrade/eucjp.py cat "$f" > ".work/utf8/$f" 2>/dev/null || iconv -f "${SRC_ENCODING:-EUC-JP}" -t UTF-8 -c "$f" > ".work/utf8/$f"
    n=$((n + 1))
  done < <(find "$d" -type f)
done
echo "$n ファイルを .work/utf8/ に書き出しました（読み取り専用の写し）"
