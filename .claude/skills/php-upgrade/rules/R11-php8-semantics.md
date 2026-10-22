---
id: R11
title: PHP 8 で意味が変わった比較・関数（count、文字列と数値の比較など）
phase: 3B
category: 意味が変わった仕様
order: 110
detect:
  - '\bcount\s*\(\s*\$'
  - '\bsizeof\s*\(\s*\$'
  - '[!=]=\s*0\b(?!\.)'
  - '\b0\s*[!=]=(?!=)'
  - '\b(in_array|array_search)\s*\([^)]*\)'
  - '\bswitch\s*\(\s*\$'
---
## 何が起きるか
- **`count(null)` / `count("str")` は TypeError（Fatal）。** 旧は 0 / 1 を返していた。未定義変数（R03）と組み合わさって頻出。
- **文字列と数値の比較**（PHP 8.0）: 数値でない文字列と数値の `==` は、数値を文字列にして比較するようになった。
  - `"" == 0`: 旧 true → 新 false
  - `"abc" == 0`: 旧 true → 新 false
  - `"1abc" == 1`: 旧 true → 新 false
  - `null == 0` は今も true。`"1" == "01"` は今も true。
  `switch` と `in_array` / `array_search`（非 strict）も同じ規則。
- 未定義の変数・配列キーの参照は Notice → Warning（旧環境で `E_NOTICE` を抑止していると気づかない）。
- 組み込み関数の非 nullable 引数への `null` は 8.1 で Deprecated（`trim(null)`、`htmlspecialchars(null)`、`strlen(null)`）。

## 直し方
- `count($x)`: `$x` が必ず配列になるよう初期化する（R03）。どうしても不定なら `is_array($x) ? count($x) : 0` だが、その前に初期化で直せないか確認。
- 入力値と数値の比較は、**旧の評価結果を保つ**ように書き換える。旧の規則は「文字列を先頭の数値部分に変換して比較」なので:
  ```php
  // 旧 PHP（7 以前）の「文字列 → 数値」変換。先頭の数値部分を取り、なければ 0
  function legacy_num($v) { return is_numeric($v) ? $v + 0 : (float)$v; }
  if (legacy_num($category) != 0) { ... }   // 旧: if ($category != 0)
  ```
  `(int)` は `"2.5"` を 2 にしてしまうので、旧と一致させたいなら上のように `float` を経由する。
  - 旧の「16 進文字列（`"0x1A"`）も数値扱い」までは再現しない（5.x の挙動。7.0 で廃止）。必要なら人に上げる。
- 未定義キーは `isset($a['k']) ? $a['k'] : null`（5.0 互換。`??` は 7.0 以降なので 3A では使わない。3B 以降は可）。

## 落とし穴
- 比較の結果が変わる場所は、エラーにならずに**分岐が変わる**。検索条件が空のときに SQL エラーになる、全件のはずが 0 件になる、など。
  `!= 0` / `== 0` / `== ""` / `switch` を grep で総当たりし、片方が入力値（文字列）かどうかを確認する。
- `<option>` の selected 判定（`$id == $selected`）のように、配列キー（整数）と入力値（文字列）を比べる箇所も同じ。
