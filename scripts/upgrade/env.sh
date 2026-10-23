# scripts/upgrade/ のシェルスクリプトが読む共通設定。SRC_ENCODING を .upgrade.env から読む（環境変数が優先）
_UPGRADE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
if [ -z "${SRC_ENCODING:-}" ] && [ -f "$_UPGRADE_ROOT/.upgrade.env" ]; then
  SRC_ENCODING=$(sed -nE 's/^[[:space:]]*SRC_ENCODING[[:space:]]*=[[:space:]]*([^[:space:]]+).*/\1/p' "$_UPGRADE_ROOT/.upgrade.env" | head -1)
fi
export SRC_ENCODING=${SRC_ENCODING:-EUC-JP}
