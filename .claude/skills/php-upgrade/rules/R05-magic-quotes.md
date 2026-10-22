---
id: R05
title: magic_quotes 依存の除去
phase: 3A
category: 実行設定依存
order: 80
detect:
  - '\bstripslashes\s*\('
  - '\baddslashes\s*\('
  - '\bget_magic_quotes_(gpc|runtime)\s*\('
  - '\bset_magic_quotes_runtime\s*\('
---
## 何が起きるか
`magic_quotes_gpc` は PHP 5.4 で削除。旧環境では入力値に自動でエスケープがかかっていた。
- `magic_quotes_sybase = Off`: `'` `"` `\` NUL の前に `\`
- `magic_quotes_sybase = On`: `'` → `''` のみ（`\` はそのまま）。**`stripslashes()` もこの設定に従い、`''` → `'` に戻すだけになる**

新環境では入力値が生のまま来るので、
1. SQL に文字列連結していた箇所は **SQL インジェクション + `'` を含む入力で SQL エラー** になる。
2. `stripslashes()` で戻していた箇所は、生の `\` を消してしまう（sybase=Off だった場合）。

## 直し方
- まず旧環境の php.ini（`magic_quotes_gpc` / `magic_quotes_sybase`）を確認する。ここで挙動が全く違う。
- 入力値由来で SQL に入る値はプレースホルダに置き換える（R09 の DB ラッパーで行う）。手でエスケープ関数を足すのは避ける。
- 表示のための `stripslashes($x)` は `$x` にする（入力は生になったので）。
- 「入力値のエスケープされた形」を前提にしていた処理（長さチェック、再表示、ハッシュ計算）を探す。

## 落とし穴（バグ互換か仕様変更かの判断が要るもの。必ず分類案を付けて人に上げる）
- **入力チェックの再表示**: 旧環境では `O'Reilly` が `O''Reilly`（sybase）や `O\'Reilly` で再表示されていた。新環境では生の値が出る。
- **長さチェック**: `strlen($name) > 100` がエスケープ後の長さで判定されていた。`'` を含む値の境界が変わる。
- **パスワードハッシュ**: `md5($password)` がエスケープ後の値のハッシュだった。`'` `\` を含むパスワードのユーザーはログインできなくなる（または逆）。
  既存ハッシュの作られ方を確認し、必要なら旧挙動を再現する関数を用意して人に判断を仰ぐ。
- 旧環境の `magic_quotes_runtime` が On だった場合は、DB やファイルから読んだ値にもエスケープがかかっていた。

## 学び（実施記録）
- 2026-10-22-01: `magic_quotes_sybase = On` の環境だったため、再表示のバグは `O\'Reilly` ではなく `O''Reilly` になる（解答キー B01 の記述は sybase=Off を前提にしている）。**php.ini を見ずに想定しない。**
