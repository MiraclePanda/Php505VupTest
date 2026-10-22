# サンプルアプリに仕込んだ移行課題（解答キー）

`app/` には、PHP 5.0.5 → 8.5 の移行で実際によく問題になる書き方を意図的に入れてある。
移行エージェントの評価では、この一覧を **エージェントに見せずに** 実行し、検出・修正できた割合を測る。

凡例: 致命 = PHP 8.5 で Fatal/Parse error、挙動 = エラーは出ないが結果が変わる、警告 = Deprecated/Warning、DB = MySQL 側、安全 = セキュリティ上の問題（互換性とは別に判断）

## 実行環境（php.ini）依存

| # | 内容 | 場所 | 種別 | 移行先での扱い |
|---|------|------|------|----------------|
| T01 | `register_globals` 前提（`$keyword`, `$id`, `$login_id` など） | 全画面 | 挙動 | 5.4 で廃止。未定義変数になる。`$_GET`/`$_POST` から明示的に取得 |
| T02 | `magic_quotes_gpc` 前提のエスケープ（SQL 組み立て、`stripslashes`） | index.php, edit.php, login.php, Product.class.php | 挙動/安全 | 5.4 で廃止。プリペアドステートメントに置換し、`stripslashes` を除去 |
| T03 | 短縮タグ `<?` | 全 .php, header.inc | 致命（ソース露出） | 8.5 環境は `short_open_tag=Off`。そのままだと **ソースがそのまま表示される**。`<?php` に置換（`<?=` は常に有効） |
| T04 | `$HTTP_SERVER_VARS` / `$HTTP_POST_VARS` | edit.php, login.php | 挙動 | 5.4 で廃止。`$_SERVER` / `$_POST` |
| T05 | `$PHP_SELF`（グローバル） | index.php | 挙動/安全 | `$_SERVER['PHP_SELF']` は XSS の温床。`htmlspecialchars` するか固定パスに |
| T06 | `session_register` / `session_is_registered` / `session_unregister` | login.php, functions.inc, logout.php | 致命 | 5.4 で削除。`$_SESSION` |

## 言語仕様

| # | 内容 | 場所 | 種別 | 移行先での扱い |
|---|------|------|------|----------------|
| T07 | 実行時の参照渡し `format_price(&$row)` | index.php | 致命（Parse error） | 5.4 で削除。関数定義側を `function format_price(&$row)` に |
| T08 | `=& new` | edit.php | 致命（Parse error） | 7.0 で削除。`= new` |
| T09 | PHP4 形式コンストラクタ `function Product()` | Product.class.php | 挙動 | 8.0 でただのメソッドになり、**呼ばれなくなる**（`$errors` が初期化されない） |
| T10 | 非 static メソッドの静的呼び出し `Product::find()` | edit.php | 致命 | 8.0 で Error。`static function` にする |
| T11 | `var` によるプロパティ宣言 | Product.class.php | なし | 動くが `public` に揃えるのが望ましい。8.2 以降、未宣言プロパティの動的生成は Deprecated |
| T12 | 波括弧による文字列オフセット `$code{0}` | functions.inc | 致命 | 8.0 で削除。`$code[0]` |
| T13 | `ereg()` | index.php, Product.class.php | 致命 | 7.0 で削除。`preg_match('/^...$/', ...)` |
| T14 | `split()` | index.php | 致命 | 7.0 で削除。`explode` または `preg_split` |
| T15 | `each()` | functions.inc | 致命 | 8.0 で削除。`foreach` |
| T16 | `create_function()` | functions.inc | 致命 | 8.0 で削除。無名関数または `strcmp` を直接渡す |
| T17 | `(integer)` キャスト | edit.php | 警告 | 8.5 で非標準キャスト名が Deprecated。`(int)` |
| T18 | `count()` に未定義変数（null）を渡す `count($errors)` | edit.php（GET 時） | 致命 | 8.0 で TypeError。`$errors = array();` で初期化 |
| T19 | 数値と文字列の比較 `$category != 0`（`category=""` のとき） | index.php | 挙動 | 8.0 で比較規則が変わり、`"" != 0` が true に。**「すべて」で検索すると SQL エラーになる**。特性テスト 05 で検出 |
| T20 | `htmlspecialchars()` の既定フラグ | functions.inc `h()` | 挙動 | 8.1 で既定が `ENT_QUOTES \| ENT_SUBSTITUTE` に変わり `'` が `&#039;` になる。出力が変わる（特性テスト 09, 16, 19）。仕様変更として受け入れるか判断 |
| T21 | `default_charset` 未設定 | php.ini | 挙動 | 5.6 以降の既定は UTF-8。`Content-Type` ヘッダに `charset=UTF-8` が付く |

## DB アクセス

| # | 内容 | 場所 | 種別 | 移行先での扱い |
|---|------|------|------|----------------|
| T22 | `mysql_*` 関数（`mysql_connect`, `mysql_query`, `mysql_result`, `mysql_fetch_array` など） | 全体 | 致命 | 7.0 で削除。PDO（推奨）または mysqli |
| T23 | `@` でのエラー抑制と `or die(mysql_error())` | db.inc | 安全 | エラー詳細と SQL を画面に出している。例外処理とログ出力へ |
| T24 | 文字列連結による SQL 組み立て（SQL インジェクション） | index.php（`category`, `page` 経由も含む）, login.php, Product.class.php | 安全 | プリペアドステートメント |
| T25 | `MyISAM` / `utf8`（utf8mb3） | db/init/01_schema.sql | DB | MySQL 8.4 でも動くが、InnoDB / utf8mb4 への変更を検討 |
| T26 | `SET NAMES` を発行せず、サーバ側設定に文字コードを依存 | db.inc | DB | 接続時に `charset=utf8mb4` を指定 |

## セキュリティ（互換性とは別枠で判断する）

| # | 内容 | 場所 |
|---|------|------|
| S01 | 反射型 XSS（該当なしメッセージで `$keyword` を無エスケープ出力） | index.php |
| S02 | `include/*.inc` が Web から直接参照でき、DB パスワードがテキストで見える | include/config.inc |
| S03 | パスワードが無塩 MD5 | login.php, users テーブル |
| S04 | CSRF 対策なし、ログイン時のセッション ID 再生成なし | edit.php, login.php |

## 当時のバグ（バグ互換にするか判断が要るもの）

| # | 内容 | 場所 |
|---|------|------|
| B01 | 入力エラーで再表示すると `'` が `\'` になる（magic_quotes の値を `stripslashes` せず表示） | edit.php（特性テスト 18） |
| B02 | 商品名の長さを `strlen`（バイト数）で判定しており、日本語だと約 33 文字で「長すぎます」になる | Product.class.php |
| B03 | 存在しない商品 ID で `die()` するため、ステータスは 200 のままヘッダ・フッタもない | edit.php（特性テスト 17） |
