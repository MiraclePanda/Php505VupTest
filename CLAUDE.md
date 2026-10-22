# CLAUDE.md

PHP 5.0.5 で作られたアプリを PHP 8.5 へ移行するプロセスを検証するリポジトリ。
プロセスは `docs/upgrade-process.md` に従う。

## 構成

- `app/` 移行対象のアプリ（PHP 5.0.5 時代の書き方）。`include/*.inc` も PHP ファイルとして扱う。**移行元なので書き換えない**
- `newapp/` 移行結果。`newapp/app/` が PHP 8.5 で動くアプリ、`newapp/db/` が DB 移行スクリプト、`newapp/docs/` が棚卸し・差分の分類案・移行レポート
- `app/`、`newapp/app/`、`db/init/` は **EUC-JP**。読むときは `iconv -f EUC-JP -t UTF-8` か `scripts/upgrade/eucjp.py cat` を通す。Edit / Write は UTF-8 以外を扱えないので、書き換えは `scripts/upgrade/eucjp.py replace` / `write` で行う（UTF-8 化は `docs/upgrade-process.md` の 3D で行う）
- `db/init/` スキーマと初期データ（特性テストの前提）。本番は Symfoware（ODBC 接続）、検証では SQLite の ODBC ドライバで代用（DSN 名は `shop`）
- `db/init.php` DB 初期化スクリプト。旧新両方の PHP で動く（`scripts/reset-db.sh` から呼ぶ）
- `docker/` 旧環境（PHP 5.0.5 / ODBC + SQLite 2、:8050）と新環境（PHP 8.5 / ODBC + SQLite 3、:8085）
- `tests/characterization/` 特性テスト。`golden/` が旧環境の記録、`actual/` は実行結果（コミットしない）
- `docs/sample-app-traps.md` 仕込んだ課題の解答キー。**移行エージェントの評価中は読まないこと**（フックで拒否される。採点は `upgrade-retro` スキルで行う）
- `.claude/skills/php-upgrade/` 移行の手順（スキル）、ルールカタログ（`rules/`）、蓄積したノウハウ（`knowledge/`）
- `.claude/agents/` 棚卸し・移行・検証・レビューの各エージェント
- `scripts/upgrade/` 移行用の道具（EUC-JP 編集、構文チェック、検出、検証）

## 移行作業のルール

- 1 つの移行ルールにつき 1 コミット。コミットごとに構文チェックと特性テストを通す
- 互換移行と改善（セキュリティ修正、リファクタリング）を同じコミットに混ぜない
- 特性テストの差分を自分で承認しない。回帰か仕様変更かの分類案を付けて人に上げ、承認されたものだけ `docs/known-differences.md` に記録する
- `tests/characterization/golden/` は旧環境で記録したもの以外で上書きしない
- 構文チェック: `scripts/upgrade/lint.sh newapp/app`（PHP 8.5 の `php -l`。Deprecated も失敗扱い。短縮タグは検出できないので `scripts/upgrade/scan.py --rule R01` も見る）
- 検証一式: `scripts/upgrade/verify.sh <label>`（新環境の起動、DB 初期化とデータ移行、特性テスト、PHP エラー検出、前ステップとの差分）
- 移行の進め方は `/php-upgrade` スキル、終わったら `/upgrade-retro` スキルで振り返り、学びを `.claude/skills/php-upgrade/` に反映する
