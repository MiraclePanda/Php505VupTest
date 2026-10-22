# CLAUDE.md

PHP 5.0.5 で作られたアプリを PHP 8.5 へ移行するプロセスを検証するリポジトリ。
プロセスは `docs/upgrade-process.md` に従う。

## 構成

- `app/` 移行対象のアプリ（PHP 5.0.5 時代の書き方）。`include/*.inc` も PHP ファイルとして扱う
- `db/init/` スキーマと初期データ（特性テストの前提）
- `docker/` 旧環境（PHP 5.0.5 / MySQL 5.5、:8050）と新環境（PHP 8.5 / MySQL 8.4、:8085）
- `tests/characterization/` 特性テスト。`golden/` が旧環境の記録、`actual/` は実行結果（コミットしない）
- `docs/sample-app-traps.md` 仕込んだ課題の解答キー。**移行エージェントの評価中は読まないこと**

## 移行作業のルール

- 1 つの移行ルールにつき 1 コミット。コミットごとに構文チェックと特性テストを通す
- 互換移行と改善（セキュリティ修正、リファクタリング）を同じコミットに混ぜない
- 特性テストの差分を自分で承認しない。回帰か仕様変更かの分類案を付けて人に上げ、承認されたものだけ `docs/known-differences.md` に記録する
- `tests/characterization/golden/` は旧環境で記録したもの以外で上書きしない
- 構文チェック: `docker run --rm -v "$PWD/app:/app" php:8.5-cli sh -c 'for f in $(find /app -name "*.php" -o -name "*.inc"); do php -l "$f"; done'`
