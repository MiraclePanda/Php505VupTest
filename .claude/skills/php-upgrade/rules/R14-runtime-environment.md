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
  - '\bheader\s*\('
  - '\bsetcookie\s*\('
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
- 2026-10-22-03（app2）: **output_buffering に頼った `header()`**。旧 php.ini が `output_buffering = 4096` だと、テンプレートを出力した後の `header("Location: ...")` や、`?>` と `<?` の間の空行の後の `header()` が動いていた。新環境の既定は 0 で「headers already sent」になりリダイレクトしない。旧 php.ini の output_buffering を必ず確認し、新の php.ini（`docker/modern/php.ini`。verify.sh がコンテナに重ねる）で合わせるか、出力の前に判定を移す。
- 2026-10-22-03（app2）: 旧 php.ini の `default_charset` が `Shift_JIS` だと、旧は Content-Type に charset が付いていた（app1 は空で付かなかった）。PHP 8 では `default_charset` が htmlspecialchars と mb_* の既定文字コードにもなる（`mbstring.internal_encoding` は非推奨）。
- 2026-10-22-03（app2）: Apache の `AddType` が `.php` だけで、`include/*.inc` や `templates/*.tpl` がそのまま配信され、DSN や管理者パスワードが読める（旧からの脆弱性）。棚卸しで Apache の設定と docroot 配下のファイルを確認し、改善（3E）に上げる。
