# サンプルアプリに仕込んだ移行課題（解答キー）

`app/` には、PHP 5.0.5 → 8.5 の移行で実際によく問題になる書き方を意図的に入れてある。
移行エージェントの評価では、この一覧を **エージェントに見せずに** 実行し、検出・修正できた割合を測る。

凡例: 致命 = PHP 8.5 で Fatal/Parse error、挙動 = エラーは出ないが結果が変わる、警告 = Deprecated/Warning、DB = DB・データ側、安全 = セキュリティ上の問題（互換性とは別に判断）

## 実行環境（php.ini）依存

| # | 内容 | 場所 | 種別 | 移行先での扱い |
|---|------|------|------|----------------|
| T01 | `register_globals` 前提（`$keyword`, `$id`, `$login_id` など） | 全画面 | 挙動 | 5.4 で廃止。未定義変数になる。`$_GET`/`$_POST` から明示的に取得 |
| T02 | `magic_quotes_gpc` + `magic_quotes_sybase` 前提のエスケープ（`'` → `''`。SQL 組み立て、`stripslashes`） | index.php, edit.php, login.php, Product.class.php | 挙動/安全 | 5.4 で廃止。プリペアドステートメントに置換し、`stripslashes` を除去 |
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
| T21 | `default_charset` 未設定 | php.ini | 挙動 | 5.6 以降の既定は UTF-8。EUC-JP のページに `Content-Type: text/html; charset=UTF-8` が付き、**ブラウザで文字化けする** |

## 文字コード（EUC-JP）

| # | 内容 | 場所 | 種別 | 移行先での扱い |
|---|------|------|------|----------------|
| E01 | ソース・データ・画面がすべて EUC-JP | app/ 全体, db/init/ | 挙動 | 互換移行では EUC-JP のまま動かし、UTF-8 化は独立したステップにする（下記 E02〜E05 が同時に効くため） |
| E02 | `htmlspecialchars()` の既定文字コード | functions.inc `h()` | 挙動 | 5.4 以降の既定は UTF-8。EUC-JP の文字列は不正な UTF-8 として扱われ、8.1 以降は U+FFFD に置換される（5.4〜8.0 は空文字列）。第 3 引数に `'EUC-JP'` を指定 |
| E03 | `mbstring.internal_encoding` に依存した `mb_convert_kana()` | index.php | 挙動 | `mbstring.internal_encoding` は 8.0 で削除。既定の UTF-8 で処理され、全角スペースの区切りが効かなくなる（特性テスト 03）。エンコーディング引数を明示 |
| E04 | `strlen()` による長さチェック（EUC-JP は 1 文字 2 バイト） | Product.class.php | 挙動 | UTF-8 化すると 1 文字 3 バイトになり、上限が実質的に変わる。`mb_strlen` に変えるかは仕様判断 |
| E05 | カテゴリの並び順が EUC-JP のバイト順（`strcmp`） | functions.inc | 挙動 | UTF-8 化すると並び順が変わる |
| E06 | ソースの日本語文字列とコメント | 全ファイル | 作業 | エディタやエージェントが UTF-8 として読むと文字化けする。編集時に文字コードを壊さないこと |

## DB アクセス（本番は Symfoware、検証では SQLite で代用）

| # | 内容 | 場所 | 種別 | 移行先での扱い |
|---|------|------|------|----------------|
| T22 | `sqlite_*` 関数（`sqlite_open`, `sqlite_query`, `sqlite_fetch_array`, `sqlite_fetch_single` など） | 全体 | 致命 | 5.4 で削除。PDO_SQLITE（推奨）または SQLite3 クラス |
| T23 | `@` でのエラー抑制と `or die()`、エラー時に SQL を画面に出力 | db.inc | 安全 | 例外処理とログ出力へ |
| T24 | 文字列連結による SQL 組み立て（SQL インジェクション） | index.php（`category`, `page` 経由も含む）, login.php, Product.class.php | 安全 | プリペアドステートメント |
| T25 | DB ファイルが SQLite 2 形式 | /var/www/data/shop.db | DB | SQLite 3 では開けない。旧環境でダンプし、SQLite 3 に投入し直す（新環境の `db/init_modern.php` は、無変換で移した状態を再現している） |
| T26 | 文字列を EUC-JP のバイト列のまま格納 | DB 全体 | DB | SQLite 3 は TEXT を UTF-8 とみなす。EUC-JP のままにするか、データ移行時に UTF-8 へ変換するかを E01 と合わせて決める |

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
