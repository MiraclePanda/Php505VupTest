#!/usr/bin/env bash
# PHP 8.5 で構文チェック（php -l）する。.php 以外（.inc など）も対象にする。
#   注意: short_open_tag=Off では `<?` で始まるファイルは「ただの HTML」として通ってしまう。
#   短縮タグの検出は scan.py（R01）で行うこと。
#   usage: scripts/upgrade/lint.sh [dir_or_file...]   （既定: newapp/app）
#   環境変数 PHP85_IMAGE で使うイメージを変えられる（既定: php:8.5-cli）
#   拡張子は LINT_EXT（既定: "php inc tpl phtml"。.tpl など include されるテンプレートも PHP として扱う）で指定する。
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
IMAGE=${PHP85_IMAGE:-php:8.5-cli}
EXTS=${LINT_EXT:-php inc tpl phtml}
[ $# -eq 0 ] && set -- newapp/app
files=()
for t in "$@"; do
  t=$(realpath --relative-to="$ROOT" "$t" 2>/dev/null || echo "$t")
  if [ -d "$ROOT/$t" ]; then
    for e in $EXTS; do
      while IFS= read -r f; do files+=("$f"); done < <(cd "$ROOT" && find "$t" -type f -name "*.$e" | sort)
    done
  elif [ -f "$ROOT/$t" ]; then
    files+=("$t")
  fi
done
[ ${#files[@]} -eq 0 ] && { echo "lint: 対象ファイルなし"; exit 0; }
# ローカルの php が 8.5 ならそれを使い、なければ Docker で実行する
if command -v php >/dev/null && php -r 'exit(version_compare(PHP_VERSION, "8.5", ">=") ? 0 : 1);'; then
  RUN=(php)
else
  RUN=(docker run --rm -v "$ROOT:/src" -w /src "$IMAGE" php)
fi
out=$("${RUN[@]}" -r '
  $bad = 0;
  foreach (array_slice($argv, 1) as $f) {
    exec("php -d display_errors=1 -l " . escapeshellarg($f) . " 2>&1", $o, $rc);
    // Deprecated は php -l の終了コードに出ないが、移行では失敗として扱う
    if ($rc !== 0 || preg_grep("/Deprecated:/", $o)) { $bad++; echo "NG  ", $f, "\n   ", implode("\n   ", $o), "\n"; }
    else { echo "OK  ", $f, "\n"; }
    $o = [];
  }
  exit($bad ? 1 : 0);' -- "${files[@]}")
rc=$?
echo "$out"
exit $rc
