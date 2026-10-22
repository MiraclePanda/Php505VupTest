#!/usr/bin/env bash
# DB を初期データに戻す
#   usage: scripts/reset-db.sh legacy|modern
set -euo pipefail
ENV_NAME=${1:?usage: $0 legacy|modern}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMPOSE="docker compose -f $ROOT/docker/compose.$ENV_NAME.yml"

for f in "$ROOT"/db/init/*.sql; do
  $COMPOSE exec -T db mysql -ushop -pshop shop < "$f"
done
echo "reset: $ENV_NAME"
