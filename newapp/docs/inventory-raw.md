# 機械検出結果: app

生成: 2026-10-22 15:43 / scripts/upgrade/inventory.sh

## 旧環境の実行設定（docker/legacy/php.ini）

```ini
short_open_tag = On
register_globals = On
register_long_arrays = On
magic_quotes_gpc = On
magic_quotes_runtime = Off
magic_quotes_sybase = On
allow_call_time_pass_reference = On
error_reporting = E_ALL & ~E_NOTICE
display_errors = On
output_buffering = Off
variables_order = "EGPCS"
default_charset =
session.save_handler = files
session.save_path = /tmp
session.use_cookies = 1
session.use_trans_sid = 0
session.auto_start = 0
mbstring.language = Japanese
mbstring.internal_encoding = EUC-JP
mbstring.http_input = pass
mbstring.http_output = pass
mbstring.encoding_translation = Off
```

## ファイル一覧

- `app/edit.php` (68 行, EUC-JP)
- `app/include/Product.class.php` (77 行, EUC-JP)
- `app/include/config.inc` (14 行, EUC-JP)
- `app/include/db.inc` (24 行, EUC-JP)
- `app/include/footer.inc` (4 行, EUC-JP)
- `app/include/functions.inc` (53 行, EUC-JP)
- `app/include/header.inc` (23 行, EUC-JP)
- `app/index.php` (97 行, EUC-JP)
- `app/login.php` (41 行, EUC-JP)
- `app/logout.php` (9 行, EUC-JP)

## PHP 8.5 構文チェック（php -l）

```
NG  app/edit.php
   
   Deprecated: Non-canonical cast (integer) is deprecated, use the (int) cast instead in app/edit.php on line 19
   
   Parse error: syntax error, unexpected token ";", expecting "->" or "?->" or "[" in app/edit.php on line 22
   Errors parsing app/edit.php
NG  app/index.php
   
   Parse error: syntax error, unexpected token "&" in app/index.php on line 76
   Errors parsing app/index.php
NG  app/include/functions.inc
   
   Parse error: syntax error, unexpected token "{", expecting ";" in app/include/functions.inc on line 21
   Errors parsing app/include/functions.inc
```
（OK のファイルは省略。短縮タグのファイルは php -l を素通りするので R01 を見ること）

## register_globals 依存の候補（tools/globals-scan.php）

| ファイル | 行 | 変数 | 種別 |
|---|---|---|---|
| `app/edit.php` | 19 | `$id` | read |
| `app/edit.php` | 47 | `$errors` | conditional |
| `app/edit.php` | 57 | `$product` | conditional |
| `app/include/header.inc` | 18 | `$login_user` | include-scope |
| `app/index.php` | 13 | `$page` | isset |
| `app/index.php` | 20 | `$keyword` | read |
| `app/index.php` | 31 | `$category` | read |
| `app/index.php` | 54 | `$msg` | read |
| `app/index.php` | 58 | `$PHP_SELF` | read |
| `app/login.php` | 14 | `$login_id` | read |
| `app/login.php` | 15 | `$password` | read |
| `app/login.php` | 29 | `$error` | conditional |

# ルール別の検出候補（scan.py）

## R01 短縮オープンタグ（<? → <?php）（27 件）

| 場所 | 行 |
|---|---|
| `app/edit.php:1` | `<?` |
| `app/edit.php:47` | `<? if (count($errors) > 0) { ?>` |
| `app/edit.php:49` | `<? foreach ($errors as $err) { ?>` |
| `app/edit.php:51` | `<? } ?>` |
| `app/edit.php:53` | `<? } ?>` |
| `app/edit.php:66` | `<?` |
| `app/include/header.inc:17` | `<? if (is_login()) { ?>` |
| `app/include/header.inc:19` | `<? } else { ?>` |
| `app/include/header.inc:21` | `<? } ?>` |
| `app/index.php:1` | `<?` |
| `app/index.php:54` | `<? if ($msg == "updated") { ?>` |
| `app/index.php:56` | `<? } ?>` |
| `app/index.php:68` | `<? if ($total == 0) { ?>` |
| `app/index.php:70` | `<? } else { ?>` |
| `app/index.php:74` | `<th>記号</th><th>商品コード</th><th>商品名</th><th>カテゴリ</th><th>価格</th><th>在庫</th><? if (is_login()) { ?><th>操作</th><? } ?>` |
| `app/index.php:76` | `<? while ($row = odbc_fetch_array($result)) { format_price(&$row); ?>` |
| `app/index.php:84` | `<? if (is_login()) { ?><td><a href="edit.php?id=<?=$row['id']?>">編集</a></td><? } ?>` |
| `app/index.php:86` | `<? } ?>` |
| `app/index.php:90` | `<? if ($page > 1) { ?><a href="<?=$PHP_SELF?>?<?=$query_string?>&page=<?=$page - 1?>">&lt;&lt; 前へ</a><? } ?>` |
| `app/index.php:92` | `<? if ($page < $max_page) { ?><a href="<?=$PHP_SELF?>?<?=$query_string?>&page=<?=$page + 1?>">次へ &gt;&gt;</a><? } ?>` |
| `app/index.php:94` | `<? } ?>` |
| `app/index.php:95` | `<?` |
| `app/login.php:1` | `<?` |
| `app/login.php:29` | `<? if ($error) { ?>` |
| `app/login.php:31` | `<? } ?>` |
| `app/login.php:39` | `<?` |
| `app/logout.php:1` | `<?` |

## R02 旧スーパーグローバル（$HTTP_*_VARS, $PHP_SELF）（10 件）

| 場所 | 行 |
|---|---|
| `app/edit.php:21` | `if ($HTTP_SERVER_VARS['REQUEST_METHOD'] == "POST") {` |
| `app/edit.php:24` | `$product->code        = $HTTP_POST_VARS['code'];` |
| `app/edit.php:25` | `$product->name        = $HTTP_POST_VARS['name'];` |
| `app/edit.php:26` | `$product->category_id = $HTTP_POST_VARS['category_id'];` |
| `app/edit.php:27` | `$product->price       = $HTTP_POST_VARS['price'];` |
| `app/edit.php:28` | `$product->stock       = $HTTP_POST_VARS['stock'];` |
| `app/index.php:58` | `<form method="get" action="<?=$PHP_SELF?>">` |
| `app/index.php:90` | `<? if ($page > 1) { ?><a href="<?=$PHP_SELF?>?<?=$query_string?>&page=<?=$page - 1?>">&lt;&lt; 前へ</a><? } ?>` |
| `app/index.php:92` | `<? if ($page < $max_page) { ?><a href="<?=$PHP_SELF?>?<?=$query_string?>&page=<?=$page + 1?>">次へ &gt;&gt;</a><? } ?>` |
| `app/login.php:12` | `if ($HTTP_SERVER_VARS['REQUEST_METHOD'] == "POST") {` |

## R03 register_globals 依存の除去（0 件）

## R04 session_register 系 → $_SESSION（3 件）

| 場所 | 行 |
|---|---|
| `app/include/functions.inc:51` | `return session_is_registered("login_user");` |
| `app/login.php:18` | `session_register("login_user");` |
| `app/logout.php:6` | `session_unregister("login_user");` |

## R05 magic_quotes 依存の除去（4 件）

| 場所 | 行 |
|---|---|
| `app/index.php:50` | `$query_string = "keyword=" . urlencode(stripslashes($keyword)) . "&category=" . $category;` |
| `app/index.php:59` | `キーワード: <input type="text" name="keyword" value="<?=h(stripslashes($keyword))?>" size="30">` |
| `app/index.php:69` | `<p>「<?=stripslashes($keyword)?>」に該当する商品はありません。</p>` |
| `app/login.php:34` | `<tr><th>ログインID</th><td><input type="text" name="login_id" value="<?=h(stripslashes($login_id))?>"></td></tr>` |

## R06 削除された構文（実行時参照渡し、=& new、$s{0}、非標準キャスト）（5 件）

| 場所 | 行 |
|---|---|
| `app/edit.php:19` | `$id = (integer)$id;` |
| `app/edit.php:22` | `$product =& new Product();` |
| `app/include/functions.inc:12` | `// ※呼び出し側で参照渡しすること format_price(&$row)` |
| `app/include/functions.inc:21` | `return $code{0} . $code{1};` |
| `app/index.php:76` | `<? while ($row = odbc_fetch_array($result)) { format_price(&$row); ?>` |

## R07 PHP 4 形式のクラス（同名コンストラクタ、非 static メソッドの静的呼び出し）（10 件）

| 場所 | 行 |
|---|---|
| `app/edit.php:37` | `$product = Product::find($id);` |
| `app/include/Product.class.php:5` | `class Product` |
| `app/include/Product.class.php:7` | `var $id;` |
| `app/include/Product.class.php:8` | `var $code;` |
| `app/include/Product.class.php:9` | `var $name;` |
| `app/include/Product.class.php:10` | `var $category_id;` |
| `app/include/Product.class.php:11` | `var $price;` |
| `app/include/Product.class.php:12` | `var $stock;` |
| `app/include/Product.class.php:13` | `var $errors;` |
| `app/include/Product.class.php:28` | `// Product::find($id) で呼び出す` |

## R08 削除された関数（ereg 系、split、each、create_function など）（7 件）

| 場所 | 行 |
|---|---|
| `app/include/Product.class.php:43` | `if (!ereg("^[A-Z]{2}-[0-9]{4}$", $this->code)) {` |
| `app/include/Product.class.php:54` | `if (!ereg("^[0-9]+$", $this->price)) {` |
| `app/include/Product.class.php:57` | `if (!ereg("^[0-9]+$", $this->stock)) {` |
| `app/include/functions.inc:32` | `uasort($cats, create_function('$a, $b', 'return strcmp($a, $b);'));` |
| `app/include/functions.inc:41` | `while (list($id, $name) = each($cats)) {` |
| `app/index.php:13` | `if (!isset($page) &#124;&#124; !ereg("^[0-9]+$", $page) &#124;&#124; $page < 1) {` |
| `app/index.php:23` | `$words = split(" ", $keyword);` |

## R09 DB アクセスの集約とプレースホルダ化（14 件）

| 場所 | 行 |
|---|---|
| `app/include/Product.class.php:31` | `$result = db_query("SELECT * FROM products WHERE id = " . $id);` |
| `app/include/Product.class.php:32` | `$row = odbc_fetch_array($result);` |
| `app/include/Product.class.php:74` | `return odbc_num_rows($result);` |
| `app/include/db.inc:10` | `$conn = @odbc_connect($DB_DSN, $DB_USER, $DB_PASS) or die("DB接続エラー: " . odbc_errormsg());` |
| `app/include/db.inc:18` | `$result = @odbc_exec($conn, $sql);` |
| `app/include/db.inc:20` | `die("SQLエラー: " . odbc_errormsg($conn) . "<br>" . $sql);` |
| `app/include/functions.inc:29` | `while (odbc_fetch_row($result)) {` |
| `app/include/functions.inc:30` | `$cats[odbc_result($result, "id")] = odbc_result($result, "name");` |
| `app/index.php:36` | `$result = db_query("SELECT COUNT(*) FROM products p WHERE " . $where);` |
| `app/index.php:37` | `odbc_fetch_row($result);` |
| `app/index.php:38` | `$total = odbc_result($result, 1);` |
| `app/index.php:76` | `<? while ($row = odbc_fetch_array($result)) { format_price(&$row); ?>` |
| `app/login.php:17` | `if (odbc_fetch_row($result)) {` |
| `app/login.php:19` | `$login_user = odbc_result($result, "name");` |

## R10 文字コードの明示（htmlspecialchars、mb_*、Content-Type）（3 件）

| 場所 | 行 |
|---|---|
| `app/include/functions.inc:8` | `return htmlspecialchars($str);` |
| `app/include/header.inc:3` | `<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">` |
| `app/index.php:22` | `$keyword = trim(mb_convert_kana($keyword, "s"));` |

## R11 PHP 8 で意味が変わった比較・関数（count、文字列と数値の比較など）（5 件）

| 場所 | 行 |
|---|---|
| `app/edit.php:47` | `<? if (count($errors) > 0) { ?>` |
| `app/include/Product.class.php:60` | `return count($this->errors) == 0;` |
| `app/index.php:24` | `for ($i = 0; $i < count($words); $i++) {` |
| `app/index.php:31` | `if ($category != 0) {` |
| `app/index.php:68` | `<? if ($total == 0) { ?>` |

## R12 DB 移行と DB 側の文字コード（LIKE、並び順、長さ）（2 件）

| 場所 | 行 |
|---|---|
| `app/index.php:28` | `$where .= " AND (p.name LIKE '%" . $words[$i] . "%' OR p.code LIKE '%" . $words[$i] . "%')";` |
| `app/index.php:46` | `. " ORDER BY p.code"` |

## R13 E_ALL で Warning / Deprecated を出さない（3 件）

| 場所 | 行 |
|---|---|
| `app/include/Product.class.php:71` | `. " updated_at = '" . date("Y-m-d H:i:s") . "'"` |
| `app/include/db.inc:10` | `$conn = @odbc_connect($DB_DSN, $DB_USER, $DB_PASS) or die("DB接続エラー: " . odbc_errormsg());` |
| `app/include/db.inc:18` | `$result = @odbc_exec($conn, $sql);` |

