---
id: R08
title: 削除・変更された関数（ereg 系、split、each、create_function、__autoload、大文字小文字を区別しない定数など）
phase: 3A
category: 削除された関数
order: 30
detect:
  - '\b(ereg|eregi|ereg_replace|eregi_replace|split|spliti|sql_regcase)\s*\('
  - '\beach\s*\('
  - '\bcreate_function\s*\('
  - '\bcall_user_method(_array)?\s*\('
  - '\b(mysql_\w+|mssql_\w+|sybase_\w+)\s*\('
  - '\b(set_socket_blocking|mcrypt_\w+|money_format|hebrevc|convert_cyr_string|restore_include_path|get_magic_quotes_\w+)\s*\('
  - '\bmktime\s*\(\s*\)'
  - '\bfunction\s+__autoload\s*\('
  - '\bstrftime\s*\('
  - '\bdefine\s*\([^;]*,\s*true\s*\)'
  - '\bimplode\s*\(\s*array\s*\('
  - '\bimplode\s*\(\s*\$?\w+(\([^)]*\))?\s*,\s*["\']'
  - '\barray_key_exists\s*\([^,]+,\s*\$\w+\s*\)'
---
## 何が起きるか
Fatal error（undefined function）。

## 直し方と、意味の違い
| 旧 | 新 | 注意 |
|---|---|---|
| `ereg('pat', $s)` | `preg_match('/pat/D', $s)` | **`$` の意味が違う**: POSIX の `$` は文字列末尾のみ、PCRE の `$` は末尾の改行の前にもマッチする。`D` 修飾子を付けるか `\z` を使う。区切り文字 `/` がパターン中にあればエスケープする |
| `eregi()` | `preg_match('/pat/Di', ...)` | |
| `ereg('pat', $s, $m)` | `preg_match(..., $m)` | 戻り値が違う（ereg はマッチ長、preg は 1）。戻り値を数値として使っていないか確認 |
| `ereg_replace()` | `preg_replace()` | 置換文字列の `\\1` はそのまま使える |
| `split('pat', $s)` | 正規表現でなければ `explode()`、正規表現なら `preg_split('/pat/', $s)` | `split(" ", ...)` は 1 文字の空白なので `explode` でよい。`split(".", ...)` は**正規表現の `.`**（任意の 1 文字）なので注意 |
| `while (list($k, $v) = each($a))` | `foreach ($a as $k => $v)` | each は内部ポインタを進める。ループ後にポインタ位置を使っていないか、ループ中に配列を変更していないかを確認。直前の `reset()` は不要になる |
| `create_function('$a,$b', 'return ...;')` | 名前付き関数（5.0 互換）または無名関数（5.3+） | 3A では名前付き関数。名前の衝突に注意 |
| `call_user_method('m', $obj)` | `call_user_func(array($obj, 'm'))` | |
| `mktime()`（引数なし） | `time()` | |
| `function __autoload($c)` | `spl_autoload_register('名前付き関数')` | 8.0 で宣言自体が Fatal |
| `strftime($fmt, $t)` | `date()` の書式に置き換え | 8.1 で Deprecated。`%Y/%m/%d` → `Y/m/d` |
| `define("X", 1, true)` と小文字の `x` での参照 | 3 番目の引数を外し、参照を定義どおりの大文字に揃える | 8.0 で大文字小文字を区別しない定数は廃止。小文字の参照は**未定義定数の Error**（`php -l` では拾えない）。全ソースで定数名を大文字小文字を無視して grep する |
| `implode($array, ",")`（引数が逆） | `implode(",", $array)` | 7.4 で非推奨、8.0 で TypeError |
| `array_key_exists('k', $obj)`（オブジェクト） | `property_exists($obj, 'k')` / `isset($obj->k)` | 8.0 で TypeError。宣言済みのプロパティなら旧は常に true |
| `eregi_replace(quotemeta($kw), ...)` | `preg_replace('/' . ... . '/i', ...)` | quotemeta は `{` `}` `|` をエスケープしない。CP932 / EUC-JP の 2 バイト目がこれらの文字（CP932 の「ポ」= 0x837C など）だとパターンが壊れる。旧の挙動を保つか `preg_quote` にするかは人に上げる |

## 落とし穴
- POSIX 文字クラス `[[:alpha:]]` は PCRE でも使える。`[[:<:]]` などの単語境界は PCRE に無い（`\b`）。
- ereg はマルチバイトを考慮しない（バイト単位）。preg も `u` を付けなければバイト単位なので、EUC-JP のままなら `u` を付けないこと。
- `split` の第 3 引数 limit は `explode` / `preg_split` でも同じ意味。

## 学び（実施記録）
- 2026-10-22-01: `ereg('^[0-9]+$')` を `D` なしの preg にすると `page=2\n` が通る（旧は不一致で 1 ページ目）。特性テスト 27 で確認できるようにした。
- 2026-10-22-01: `ereg` に配列が来ても旧は不一致で済んだが、`preg_match` は TypeError。`is_string($v) && preg_match(...)` にする。
- 2026-10-22-03（app2）: 棚卸しで「新ルール案」になった `__autoload`、`strftime`、`define(..., true)`、`implode` の引数順、オブジェクトへの `array_key_exists` をこのルールに入れた。
