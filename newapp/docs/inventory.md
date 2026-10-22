# 棚卸し

- 対象: `app/`（10 ファイル、すべて EUC-JP）
- 旧環境の実行設定: `docker/legacy/php.ini`（2005 年当時の典型的な設定として作ったもの。本番の php.ini は未入手）
  - `short_open_tag=On`、`register_globals=On`、`register_long_arrays=On`、`magic_quotes_gpc=On`、**`magic_quotes_sybase=On`**（`'` → `''`、`\` はそのまま）、
    `allow_call_time_pass_reference=On`、`error_reporting=E_ALL & ~E_NOTICE`、`display_errors=On`、`default_charset` 空、`mbstring.internal_encoding=EUC-JP`、`variables_order=EGPCS`
- 新環境: PHP 8.5.12 / Apache 2.4 / unixODBC + SQLite 3 ODBC ドライバ（`docker/modern/php.ini`: `short_open_tag=Off`、`E_ALL`、`display_errors=On`、`date.timezone=Asia/Tokyo`）
- 機械検出の結果: [inventory-raw.md](inventory-raw.md)
- 移行前のアプリを新環境でそのまま動かした結果: 全ケースでソースが露出し、`h()` 未定義で Fatal（短縮タグのため include の中身が PHP として動かない）

## 課題一覧

症状: **F** = Fatal / **S** = 黙って壊れる（エラーなしで結果が変わる）/ **W** = 警告が画面に出る / **D** = 差分のみ（旧と挙動が変わるが、直すかは判断）

| # | ルール | 場所 | 内容 | 症状 | 方針 | 人の判断 |
|---|---|---|---|---|---|---|
| 1 | R01 | `index.php` `edit.php` `login.php` `logout.php` `include/header.inc`（27 箇所） | 短縮タグ `<?` | S（ソース露出） | `<?php` に置換 | 不要 |
| 2 | R02 | `edit.php:21,24-28` `login.php:12` | `$HTTP_SERVER_VARS` `$HTTP_POST_VARS` | W + S（POST 判定が常に偽） | `$_SERVER` `$_POST` | 不要 |
| 3 | R02 | `index.php:58,90,92` | `$PHP_SELF` | W + S（form の action が空） | `$_SERVER['PHP_SELF']` | 不要 |
| 4 | R03 | `index.php:13,20,31,54` | `$page` `$keyword` `$category` `$msg` を GET から暗黙取得 | S（検索条件・ページングが効かない） | `request_var()` で明示取得（EGPCS の後勝ち順を再現） | 不要 |
| 5 | R03 | `edit.php:19` | `$id` を GET（`edit.php?id=`）から暗黙取得。POST 時も URL のクエリから | S（常に id=0） | `request_var('id')` | 不要 |
| 6 | R03 | `login.php:14-15` | `$login_id` `$password` を POST から暗黙取得 | S（ログイン不能） | `request_var()` | 不要 |
| 7 | R03 | `edit.php:47` `$errors`、`login.php:29` `$error` | 条件付きでしか代入されない。旧は `?errors[]=...` `?error=...` で外から注入できた | F（`count(null)`）/ W | 先頭で初期化 | 差分（注入できなくなる）は仕様変更候補 |
| 8 | R04 | `login.php:18` `functions.inc:51` `logout.php:6` | `session_register` / `session_is_registered` / `session_unregister` | F | `$_SESSION` | 不要 |
| 9 | R04 | `include/header.inc:18` `login.php:19` | セッション変数 `$login_user` をグローバル変数として読み書き | S（ログイン名が出ない） | `$_SESSION['login_user']` | 不要 |
| 10 | R05 | `index.php:50,59,69` `login.php:34` | 表示用の `stripslashes()`。sybase=On なので `''` → `'` に戻していた | S（入力の `\` などは影響なし。`''` を含む入力の表示が変わる） | 入力が生になるので `stripslashes` を外す | 不要 |
| 11 | R05 + R09 | `index.php:28` `login.php:14` `Product.class.php:66-67` | magic_quotes 済みの値を SQL に文字列連結 | S（`'` を含む入力で SQL エラー、SQL インジェクション） | プレースホルダ（R09） | 不要 |
| 12 | R05 | `login.php:15` | `md5($password)` がエスケープ後（`'` → `''`）の値のハッシュ | D（`'` を含むパスワードの照合結果が変わる） | 生の値でハッシュ。既存ハッシュの作られ方次第 | **要** |
| 13 | R05 | `edit.php`（POST の再表示）`Product.class.php:47` | 入力エラー時の再表示と `strlen($name) > 100` がエスケープ後の値 | D（`O'Reilly` が `O''Reilly` と再表示されていた。`'` を含む名前の長さ判定が 1 字ずつ厳しかった） | 生の値で扱う（旧の再現はしない） | **要**（仕様変更候補） |
| 14 | R06 | `edit.php:19` | `(integer)` キャスト | W（Deprecated） | `(int)` | 不要 |
| 15 | R06 | `edit.php:22` | `=& new` | F（Parse error） | `= new` | 不要 |
| 16 | R06 | `functions.inc:21` | `$code{0}` | F（Parse error） | `substr($code, 0, 2)`（短いコードでも旧と同じく警告なしで空文字） | 不要 |
| 17 | R06 | `index.php:76` / `functions.inc:13` | 実行時参照渡し `format_price(&$row)`。定義は値渡し | F（Parse error）。呼び出し側の `&` だけ外すと S（価格が空欄） | 定義を `function format_price(&$row)` に | 不要 |
| 18 | R07 | `Product.class.php:15` | PHP 4 形式コンストラクタ `function Product($row)` | S（編集画面が空欄） | `__construct` | 不要 |
| 19 | R07 | `Product.class.php:29` / `edit.php:37` | 非 static の `find()` を `Product::find()` で呼ぶ | F | `static function find` | 不要 |
| 20 | R08 | `index.php:13` `Product.class.php:43,54,57` | `ereg` | F | `preg_match('/.../D')`（`$` の意味を揃える） | 不要 |
| 21 | R08 | `index.php:23` | `split(" ", ...)` | F | `explode`（区切りは 1 文字の空白で正規表現の意味なし） | 不要 |
| 22 | R08 | `functions.inc:32` | `create_function` | F | 名前付き関数 | 不要 |
| 23 | R08 | `functions.inc:40-41` | `reset` + `while (list() = each())` | F | `foreach` | 不要 |
| 24 | R09 | `db.inc` と全画面 | `odbc_*` を画面から直接呼ぶ。SQL は文字列連結 | ― | `db.inc` に `db_query($sql, $params)`、`db_fetch()`、`db_fetch_value()` を用意し、PDO_ODBC（例外モード）で実装。`odbc_execute` の「`'...'` はファイル名」仕様を避けるため PDO を選ぶ | 接続方式の選択は推奨案で進める |
| 25 | R09 / R11 | `index.php:31-32` | `$category != 0` のあと SQL に生の値を連結 | F 相当（`category=` で SQL エラー。PHP 8 では `"" != 0` が真） | 判定は旧の数値変換を再現（`legacy_num`）、値はプレースホルダ | `2abc` など不正値の結果（旧: SQL エラー、新: 0 件）は差分 |
| 26 | R10 | `functions.inc:8` `h()` | `htmlspecialchars` の既定（8.x: ENT_QUOTES、UTF-8） | S（EUC-JP の日本語が空文字列になる）+ D（`'` が `&#039;`） | `htmlspecialchars($s, ENT_COMPAT, 'EUC-JP')` | 不正な EUC-JP の入力で空になる差分は仕様変更候補 |
| 27 | R10 | `index.php:22` | `mb_convert_kana($keyword, "s")` の既定エンコーディング（旧: internal_encoding=EUC-JP、新: UTF-8） | S（全角スペース区切りが効かない、文字化け） | 第 3 引数に `'EUC-JP'` | 不要 |
| 28 | R10 | 全画面の応答ヘッダ | 新は `default_charset=UTF-8` で `Content-Type: text/html; charset=UTF-8` を送る（本文は EUC-JP） | S（ブラウザが文字化け） | `config.inc` で `Content-Type: text/html; charset=EUC-JP` を送る。`logout.php` も | **要**（旧は `text/html` のみ。charset 付きになるのは仕様変更候補） |
| 29 | R11 | `edit.php:47` | GET 時 `count($errors)`（null） | F | #7 の初期化で解消 | 不要 |
| 30 | R11 | `functions.inc:42` | `$id == $selected`（整数キーと入力文字列） | D（`2abc` など） | `legacy_num()` で旧の比較を再現 | 不要 |
| 31 | R12 | `index.php:28` / DB | SQLite 3 は文字列を UTF-8 として扱う。EUC-JP のまま入れたデータに LIKE が正しく効かない | S（日本語検索がヒットしない・誤ヒット） | DB を UTF-8 にし、`db.inc` で EUC-JP ⇔ UTF-8 を変換。データ移行スクリプト `newapp/db/migrate.php` | **要**（DB の文字コードの決定） |
| 32 | R13 | `Product.class.php:71` | `date()` のタイムゾーン（旧: 未設定 → OS の TZ、新: `Asia/Tokyo`） | D（`updated_at` の値。画面には出ない） | php.ini の設定どおり（コード変更なし） | 本番の TZ を確認 |
| 33 | R13 | `edit.php:24-28` | POST の項目が欠けると未定義キー | W | `request_var()` / `post_var()` 経由で null | 不要 |
| 34 | R13 | `db.inc:10,18` | `@odbc_*` + `die` | ― | PDO の例外を捕まえて同じ形式で `die` | エラー文言（DB のメッセージ）は環境差 |

## ルールに当てはまらない課題（いずれも改善 3E で扱う。互換移行では変えない）

| # | 場所 | 内容 |
|---|---|---|
| N1 | `index.php:69` | 検索語を `「...」に該当する商品はありません` にエスケープなしで出力（XSS） |
| N2 | `index.php:50,58,90,92` | `$PHP_SELF` と `category` をエスケープなしでリンクに出力（XSS） |
| N3 | `login.php` | MD5 パスワード、ログイン時に `session_regenerate_id` なし（セッション固定） |
| N4 | `edit.php` | CSRF 対策なし |
| N5 | `include/` | 公開ディレクトリ内に設定ファイル（`.inc` はソースとして配信される） |
| N6 | `Product.class.php:74` | `odbc_num_rows()` の戻り値（UPDATE 件数）を返すが未使用 |
| N7 | `Product.class.php:47` | `strlen` によるバイト数判定（EUC-JP の間は変わらない。UTF-8 化（3D）で影響） |

## 判断が要る点（推奨案で進める）

1. **#31 DB の文字コード**: 推奨は「DB を UTF-8、アプリとの境界で変換」。Symfoware を使い続ける場合も、DB の文字コードを UNICODE にするか EUC のままにするかで同じ判断が要る。
2. **#28 Content-Type の charset**: 推奨は `charset=EUC-JP` を付ける（付けないと PHP 8.5 では UTF-8 が付く）。旧の `text/html` のみに戻すなら `default_charset` を空にする方法もある。
3. **#12 パスワードの `'`**: 推奨は生の値でハッシュ。既存ユーザーのパスワードに `'` が含まれ、旧の画面で登録されていた場合はログインできなくなる。
4. **#13 再表示と長さ判定**: 推奨は生の値（旧の `''` 二重表示は再現しない）。
5. **#7 / #25 / #26 の不正入力・攻撃入力の挙動**: 旧と変わるが、いずれも正常な操作では起きない。
