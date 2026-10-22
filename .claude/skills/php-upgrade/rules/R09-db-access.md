---
id: R09
title: DB アクセスの集約とプレースホルダ化
phase: 3A/3C
category: DB
order: 90
detect:
  - '\bodbc_\w+\s*\('
  - '\b(mysql|pg|oci|sqlite|sybase|mssql|ibase|ifx)_\w+\s*\('
  - '(SELECT|INSERT|UPDATE|DELETE)\b[^;]*"\s*\.\s*\$'
  - '(SELECT|INSERT|UPDATE|DELETE)\b[^"]*\$\w+'
  - '''%?"\s*\.\s*[\$\w]'
  - '''\$\w+(->\w+)*'''
  - '"[^"]*\b\w+\s*=\s*\$\w+'
  - '=\s*"\s*\.\s*\$'
---
## 何が起きるか
- magic_quotes がなくなる（R05）ので、文字列連結の SQL は `'` を含む入力でエラーになり、SQL インジェクションも素通しになる。
- DB 拡張の関数（`odbc_*` など）を画面から直接呼んでいると、接続方式や DB 製品を変えるときに全画面を直すことになる。

## 直し方
1. DB ラッパー（例: `include/db.inc`）に次を用意し、画面からの `odbc_*` 直接呼び出しをなくす。
   - `db_query($sql, $params = array())`: プレースホルダ付きで実行し、結果ハンドルを返す
   - `db_fetch($result)`（連想配列）、`db_fetch_value($result)`（1 列目）、`db_affected($result)`
2. 文字列連結していた値をすべてプレースホルダ `?` に置き換える。LIKE の `%` はパラメータ側に付ける（`'%' . $w . '%'`）。
3. `LIMIT` / `OFFSET` など識別子・数値リテラルとして埋め込んでいたものは、整数にキャストしてから埋め込む（ドライバによってはプレースホルダ不可）。
4. 接続方式は `odbc_*` 継続か PDO_ODBC。PDO_ODBC（ERRMODE_EXCEPTION）を推奨。理由は下記。

## 落とし穴
- **`odbc_execute()` は、`'` で始まり `'` で終わるパラメータ値をファイル名とみなして中身を読む**（PHP の仕様）。ユーザー入力をそのまま渡すと任意ファイル読み出しになりうる（PHP 8.5.12 で `'abc'` を渡して「Can't open file abc」になることを確認）。`odbc_*` を使い続けるなら必ず回避する。PDO_ODBC にはこの挙動はない。
- PDO_ODBC も `odbc_fetch_array` も、数値列を文字列で返す（ドライバ依存）。比較や `===` の前提を変えないこと。
- 文字列連結からプレースホルダに変えると、**型の扱いが変わる**: 旧 `WHERE category_id = 2abc` は SQL エラー、新 `WHERE category_id = ?`（'2abc'）は 0 件。エラー経路の差分として分類案に書く。
- SQLite の INTEGER 型列と文字列パラメータの比較は、列のアフィニティにより数値に変換されて一致する（`'2'` = 2）。他の DB（Symfoware など）では暗黙変換の規則が違うので、数値列には `(int)` で渡すか DB の仕様を確認する。
- `odbc_num_rows()` が SELECT で返す値はドライバ依存（-1 など）。件数は `COUNT(*)` で取る。
- エラー時に SQL 文を画面に出していた（`die("SQLエラー..." . $sql)`）場合、互換移行ではメッセージ形式を残す。メッセージ本文（DB のエラー文言）は変わるので、エラー経路のテストは差分として扱う。
