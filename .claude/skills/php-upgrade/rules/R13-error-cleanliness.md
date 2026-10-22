---
id: R13
title: E_ALL で Warning / Deprecated を出さない
phase: 3B
category: 非推奨・警告
order: 130
detect:
  - '\$_(GET|POST|COOKIE|REQUEST|SERVER|SESSION)\[[^\]]+\](?!\s*=)'
  - '@\s*\w+\s*\('
  - '\bdate\s*\('
---
## 何が起きるか
旧環境は `error_reporting = E_ALL & ~E_NOTICE` で、未定義キーや未定義変数を黙って null にしていた。
PHP 8 ではこれらが Warning になり、`display_errors = On` なら**画面に出る**（特性テストで差分になる）。

## 直し方
- 入力値・セッション値の取り出しはヘルパー経由にし、未定義なら null を返す（R03）。
- `@` で抑止しているエラーは、PHP 8 でも Fatal（Error 例外）は抑止できない。DB 接続などは例外処理に置き換える。
- `date()` などタイムゾーンに依存する関数は、`date.timezone` を php.ini で明示する（旧は環境変数 TZ / OS 設定）。

## 確認
特性テストの全ケースで、応答に `Warning:` `Deprecated:` `Notice:` `Fatal error:` が含まれないこと。
`scripts/upgrade/verify.sh` が応答と Apache のエラーログの両方を確認する。
