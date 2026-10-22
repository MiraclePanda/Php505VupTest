---
id: R14
title: 実行環境（拡張、ODBC の DSN とドライバ、php.ini）
phase: 0/3C
category: 環境
order: 5
detect:
  - '\bodbc_(p?connect)\s*\('
  - 'new\s+PDO\s*\('
  - '\$DB_(DSN|HOST|USER|PASS)\b'
  - '\b(ini_set|ini_get)\s*\('
  - '\bdl\s*\('
---
## 何が起きるか
アプリのソースの外にある前提（PHP 拡張、ODBC の DSN 定義とドライバ、php.ini の値、OS のタイムゾーン）が移行先で欠けると、
コードが正しくても動かない。棚卸しがソースだけを見ていると漏れる（2026-10-22-01 で解答キー T28 を見逃した）。

## 棚卸しで確認すること
- 使っている拡張（`odbc`、`pdo_odbc`、`mbstring`、`iconv`、`session` など）と、移行先でのビルド方法（PHP 8.5 の公式イメージで odbc を入れるには configure の手当てが要る: `docker/modern/Dockerfile`）
- ODBC: DSN 名とその定義（`/etc/odbc.ini`）、ドライバ（`/etc/odbcinst.ini`）、DB 製品のクライアント。移行先サーバに同じ DSN を作る手順を移行手順に含める
- php.ini: 旧の値（`register_globals`、`magic_quotes_*`、`short_open_tag`、`default_charset`、`mbstring.*`、`error_reporting`、`display_errors`、`session.*`）と、新でどう設定するか
- タイムゾーン: 旧は OS の TZ に依存（`date.timezone` は 5.1 から）。新は `date.timezone` で明示
- cron、バッチ、`.htaccess`、Apache の設定（DirectoryIndex、AddType で `.inc` を PHP にしていないか）

## 直し方
- 移行先の環境定義（Dockerfile、構成管理）に、拡張、DSN、ドライバ、php.ini を書く。
- 移行レポートの「環境」の節に、旧と新の対応表を書く。
