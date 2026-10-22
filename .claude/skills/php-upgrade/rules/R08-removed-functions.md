---
id: R08
title: 削除された関数（ereg 系、split、each、create_function など）
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

## 落とし穴
- POSIX 文字クラス `[[:alpha:]]` は PCRE でも使える。`[[:<:]]` などの単語境界は PCRE に無い（`\b`）。
- ereg はマルチバイトを考慮しない（バイト単位）。preg も `u` を付けなければバイト単位なので、EUC-JP のままなら `u` を付けないこと。
- `split` の第 3 引数 limit は `explode` / `preg_split` でも同じ意味。

## 学び（実施記録）
- 2026-10-22-01: `ereg('^[0-9]+$')` を `D` なしの preg にすると `page=2\n` が通る（旧は不一致で 1 ページ目）。特性テスト 27 で確認できるようにした。
- 2026-10-22-01: `ereg` に配列が来ても旧は不一致で済んだが、`preg_match` は TypeError。`is_string($v) && preg_match(...)` にする。
