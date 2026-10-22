#!/usr/bin/env bash
# 新環境（PHP 8.5）のイメージを php505-modern としてビルドする。
#   通常は docker/modern/Dockerfile をそのままビルドする。
#   deb.debian.org に出られない環境（Claude Code のクラウドなど）では、ホストの apt（Ubuntu）で
#   unixODBC と SQLite ODBC ドライバの .deb を取得し、展開して使うフォールバックを行う（検証用。本番には使わない）。
#   usage: scripts/upgrade/build-modern-image.sh [image_name]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
IMAGE=${1:-php505-modern}
if docker build -t "$IMAGE" "$ROOT/docker/modern"; then
  exit 0
fi
echo "== 通常のビルドに失敗。ホストの apt で .deb を取得してビルドする（フォールバック）" >&2
command -v apt-get >/dev/null || { echo "apt-get がないためフォールバックできない" >&2; exit 1; }
CTX=$(mktemp -d)
trap 'rm -rf "$CTX"' EXIT
cp -r "$ROOT/docker/modern/." "$CTX/"
mkdir -p "$CTX/debs"
(cd "$CTX/debs" && (apt-get download unixodbc unixodbc-dev unixodbc-common libodbc2 libodbcinst2 libodbccr2 libsqliteodbc libltdl7 \
  || { sudo apt-get update >/dev/null && apt-get download unixodbc unixodbc-dev unixodbc-common libodbc2 libodbcinst2 libodbccr2 libsqliteodbc libltdl7; }))
python3 - "$CTX/Dockerfile" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s, n = re.subn(r"RUN apt-get update \\\n && apt-get install[^\n]*\\\n && rm -rf /var/lib/apt/lists/\*",
               "COPY debs /tmp/debs\nRUN for d in /tmp/debs/*.deb; do dpkg-deb -x \"$d\" /; done; ldconfig; rm -rf /tmp/debs", s)
if n != 1:
    sys.exit("Dockerfile の apt-get 行を置き換えられない（Dockerfile が変わった？）")
open(p, "w").write(s)
PY
docker build -t "$IMAGE" "$CTX"
