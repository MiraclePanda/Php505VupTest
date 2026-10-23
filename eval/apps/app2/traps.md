# app2（社内お知らせ掲示板）に仕込んだ課題（解答キー。評価者専用）

PHP 5.0.5 / Apache 2.0 / ODBC（本番 Symfoware、検証 SQLite）。ソースと DB は **Shift_JIS（CP932）**。
旧環境の php.ini は `legacy-php.ini`（app1 との違い: `magic_quotes_sybase = Off`、`output_buffering = 4096`、
`default_charset = "Shift_JIS"`、`mbstring.internal_encoding = SJIS`）。評価用の複製では `.upgrade.env` を置かない（文字コードの判定も評価対象）。

隠しテスト: `hidden/run.sh`（27 ケース）と `hidden/expectations.tsv`。客観チェック: `checks.tsv`。

| ID | 場所 | 課題 | 旧（PHP 5.0 + legacy-php.ini） | PHP 8.5 でそのまま | 期待する対応 | 種類 |
|---|---|---|---|---|---|---|
| H01 | 全 .php、`templates/header.tpl` | 短縮タグ `<?`（`.tpl` も include される PHP） | 動く | ソースが出力される | `<?php` に。`<?=` はそのままでよい | Fatal 相当 |
| H02 | 全ファイル、DB | 文字コードが CP932（app1 は EUC-JP） | — | 道具が EUC-JP 前提だと読み書きで壊す | `.upgrade.env` に CP932 を設定。mb_* と htmlspecialchars は `SJIS-win` / `CP932`（H27） | 道具 |
| H03 | `include/common.inc` | `__autoload()` | クラスを自動で読む | 8.0 で宣言自体が Fatal | `spl_autoload_register` | Fatal |
| H04 | `common.inc`、`index.php` | 大文字小文字を区別しない定数 `define("LIST_MAX", 3, true)` と `list_max` の参照 | 動く | 3 番目の引数は無視（Warning）、`list_max` は未定義定数で Error | `true` を外し、参照を `LIST_MAX` に揃える | Fatal |
| H05 | `index.php` | `switch ($sort)` の `case 0:` が先 | `"title" == 0` が真なので、**sort=title でも新しい順**（旧のバグ） | `"title" == 0` が偽になり、件名順に変わる | 旧の評価結果を保つ（`case 0` を旧の比較規則で判定）。件名順を直すなら改善として人に上げる | 黙って変わる |
| H06 | `index.php` | 括弧のない入れ子の三項演算子 | 左結合: 重要なお知らせは「新着」になる（旧のバグ） | 8.0 でコンパイルエラー | 左結合の括弧 `($row['important'] ? "重要" : is_new(...)) ? "新着" : "通常"` で旧の結果を保つ。直すなら人に上げる | Fatal＋意味 |
| H07 | `common.inc` | 引数なしの `mktime()` | 現在時刻 | 8.0 で ArgumentCountError | `time()` | Fatal |
| H08 | `common.inc` | `strftime()` | 動く | 8.1 で Deprecated | `date("Y/m/d", ...)` | 警告 |
| H09 | `index.php` | `ereg("^[0-9]+$", $page)` | `$` は末尾のみ | 削除（Fatal） | `preg_match('/^[0-9]+$/D')` | Fatal |
| H10 | `index.php` | `eregi_replace(quotemeta(h($kw)), "<b>\\0</b>", ...)` | 大文字小文字を無視した強調 | 削除（Fatal） | `preg_replace('/' . preg_quote(..., '/') . '/i', '<b>$0</b>', ...)`。CP932 の 2 バイト目 `0x5C` を含む語（ソ、表）でも動くこと | Fatal |
| H11 | `Model.class.php`、`Notice.class.php` | PHP4 コンストラクタと `parent::Model()` | `new Notice()` で table が入る | `Notice()` はただのメソッドになり table が空 → SQL エラー | `__construct` と `parent::__construct` | 黙って壊れる |
| H12 | `Model.class.php` | 動的プロパティ `$this->loaded` | 動く | 8.2 で Deprecated | プロパティを宣言 | 警告 |
| H13 | `view.php` | `call_user_method()` | 動く | 削除（Fatal） | `$notice->load($id)` など | Fatal |
| H14 | `view.php` | `array_key_exists('tags', $notice)`（オブジェクト） | プロパティの有無 | 8.0 で TypeError | `property_exists` / `isset` | Fatal |
| H15 | `view.php` | `split("[ ,]+", ...)` | 動く | 削除（Fatal） | `preg_split('/[ ,]+/', ...)` | Fatal |
| H16 | `post.php` | `$HTTP_SERVER_VARS` | 動く | 削除（未定義） → POST が処理されない | `$_SERVER` | 黙って壊れる |
| H17 | `post.php` | `"${title_disp}"` | 動く | 8.2 で Deprecated | `"{$title_disp}"` | 警告 |
| H18 | `export.php` | `implode(array(...), ",")`（引数が逆） | 動く | 8.0 で TypeError | `implode(",", array(...))` | Fatal |
| H19 | `view.php`、`export.php` | 出力の後の `header()`（`view.php` はヘッダのテンプレートを出してから Location、`export.php` は `?>` と `<?` の間の空行） | `output_buffering = 4096` で動く | 新環境の既定は 0。「headers already sent」の Warning でリダイレクトしない、CSV の Content-Type が付かない | 新環境の php.ini に `output_buffering = 4096`（R14）か、出力の前に判定を移す。CSV の先頭の空行は旧の挙動（記録のみ） | 黙って壊れる |
| H20 | 全画面、`admin/delete.php` | register_globals（`$kw`、`$page`、`$sort`、`$msg`、`$id`、`$title` など、`$PHP_AUTH_USER` / `$PHP_AUTH_PW`） | 動く | 未定義 | 入力の取り出しを明示。`$_SERVER['PHP_AUTH_USER']` | 黙って壊れる |
| H21 | `common.inc` の `q()`、全画面の `stripslashes` | magic_quotes_gpc（**sybase=Off**: `'` → `\'`、`"` → `\"`、`\` → `\\`）。`q()` は `\'` を `''` に直すだけ | SQL は正しく組める | `'` がエスケープされず SQL エラー・インジェクション | 値をプレースホルダで渡す（R09）か、`q()` で `'` を `''` に | 黙って壊れる |
| H22 | DB の既存データ | **magic_quotes の残骸が DB に保存されている**（`\"`、`\\`、CP932 の `0x5C` の重複）。表示は `stripslashes` で戻している | 正しく表示・検索できる | magic_quotes がなくなると、新しいデータは残骸なし・古いデータは残骸ありの混在になる。`stripslashes` を外すと古いデータに `\` が出る、残すと新しいデータの `\` が消える。検索も古いデータに当たらない（`ソフト` で 0 件） | データ移行で残骸を除く（`stripslashes` を一度だけ適用）＋表示の `stripslashes` を外す。または入力側で `addslashes` を再現して一貫させる。どちらにしたか人に上げる | 黙って壊れる |
| H23 | `index.php`、`post.php` | CP932 の `0x5C` と `stripslashes` | magic_quotes で `0x5C` が重複してから `stripslashes` で戻るので正しい | magic_quotes なしで `stripslashes` だけ残すと「ソ」「表」の 2 バイト目が消えて文字化け | 入力値への `stripslashes` を外す | 黙って壊れる |
| H24 | `post.php` | `mb_strlen()` の文字コード省略（30 文字制限） | `mbstring.internal_encoding = SJIS` で文字数 | 既定 UTF-8 で CP932 のバイト列を数え、30 文字の件名が「30 文字以内で」エラー | `mb_strlen($s, 'SJIS-win')` | 黙って変わる |
| H25 | `common.inc` の `h()` | `htmlspecialchars` の既定 | ENT_COMPAT・文字コードを見ない | ENT_QUOTES・UTF-8。CP932 の文字列は空文字になる | `htmlspecialchars($s, ENT_COMPAT, 'SJIS-win')`（または CP932） | 黙って壊れる |
| H26 | 全画面 | `default_charset = "Shift_JIS"`（旧 php.ini） | `Content-Type: text/html; charset=Shift_JIS` | `charset=UTF-8` で文字化け | 新の php.ini に `default_charset = "Shift_JIS"` か、ヘッダで明示（app1 は「付かない」だったのと逆） | 黙って壊れる |
| H27 | データ（①、髙）、変換処理 | 機種依存文字（NEC 特殊文字、IBM 拡張） | バイト列のまま | `SJIS` で変換すると `?` になる | 変換は `SJIS-win` / `CP932` を使う。DB を UTF-8 化するなら移行スクリプトで往復検査 | 黙って壊れる |
| H28 | `index.php` の LIKE | CP932 の 2 バイト目が ASCII（`t` で「フ」に当たる） | `kw=t` で 2 件（誤ヒット）。強調で文字の途中に `<b>` が入る | DB を UTF-8 にすれば 0 件 | 仕様変更候補として上げる | 差分のみ |
| H29 | `post.php` | `date()` のタイムゾーン | OS の設定 | `date.timezone` | 新の php.ini で明示（既に Asia/Tokyo）。旧サーバの TZ を確認 | 要確認 |
| H30 | `admin/delete.php` | Basic 認証の受け渡し | mod_php で `$PHP_AUTH_USER` | `$_SERVER['PHP_AUTH_USER']`（CGI / FPM なら別途設定） | R14 に記録 | 環境 |
| H31 | `header.tpl`、`index.php` | XSS（`$msg`、`$sort` をそのまま出力） | 外からの値が出る | register_globals がなければ `$msg` は出ない | 改善（3E）として記録 | セキュリティ |
| H32 | `Model::load`、`admin/delete.php` | SQL インジェクション（`$id` の連結） | — | — | プレースホルダ（R09） | セキュリティ |
| H33 | `common.inc` | 管理者のパスワードの直書き | — | — | 改善（3E）として記録 | セキュリティ |
| H34 | `view.php?id=abc` | 不正な id で SQL エラーを画面に出す（旧のバグ） | 「SQLエラー」 | — | 記録（直さない） | 当時のバグ |
| H35 | `Model.class.php`、`Notice.class.php` | `var` | 動く | 動く | 対応不要として記録 | 対応不要 |
| H36 | `db/init`、移行スクリプト | `VARCHAR(60)`（件名 30 文字 × 2 バイト） | 収まる | UTF-8 化すると 90 バイト | DB を UTF-8 にするなら人に上げる | 要確認 |
| H37 | `export.php` | CSV は Shift_JIS のまま（Excel 用） | — | DB を UTF-8 にしたら CP932 に戻して出す必要 | 機種依存文字を含めて往復 | 黙って壊れる |

## 追加発見（2026-10-22-03 の実施で見つかり、解答キーに足したもの）

| ID | 場所 | 課題 | 見つけた担当 |
|---|---|---|---|
| H38 | Apache の設定 | `AddType` が `.php` だけなので `include/common.inc` と `templates/*.tpl` がそのまま配信され、DSN と管理者パスワードが読める | 棚卸し |
| H39 | データ移行 | ODBC が VARCHAR を宣言長で読み出すため、残骸の `\` で 60 バイトを超えた件名が移行元から読んだ時点で切れる（md5 の照合では気づかない） | 最後の意味レビュー |
| H40 | DB との変換 | CP932 の重複コード（髙 0xEEE0 → 0xFBFC など）が往復で正規化され、強調表示が一致しなくなる。新しい投稿でも起きる | 移行（R12）と最後の意味レビュー |
| H41 | 旧の表示 | 旧も `VARCHAR(60)` を宣言長で読んでいたため、残骸を含む長い件名は 60 バイトで切れて表示されていたと推定（新は全部表示） | 最後の意味レビュー |
