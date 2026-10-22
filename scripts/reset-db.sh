#!/usr/bin/env bash
# DB を初期データに戻す
#   usage: scripts/reset-db.sh legacy|modern
set -euo pipefail
ENV_NAME=${1:?usage: $0 legacy|modern}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
case "$ENV_NAME" in
  legacy) PHP=/usr/local/php5/bin/php ;;
  modern) PHP=php ;;
  *) echo "usage: $0 legacy|modern" >&2; exit 2 ;;
esac
docker compose -f "$ROOT/docker/compose.$ENV_NAME.yml" exec -T web "$PHP" "/var/www/db/init_$ENV_NAME.php"
