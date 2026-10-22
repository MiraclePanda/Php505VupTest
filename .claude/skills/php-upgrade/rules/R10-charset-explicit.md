---
id: R10
title: 文字コードの明示（htmlspecialchars、mb_*、Content-Type）
phase: 3A
category: 文字コード
order: 100
detect:
  - '\bhtml(specialchars|entities)\s*\('
  - '\bhtml_entity_decode\s*\('
  - '\bmb_\w+\s*\('
  - 'charset='
  - '\bheader\s*\(\s*["'']Content-Type'
---
## 何が起きるか
| 項目 | PHP 5.0（旧） | PHP 8.5（新） |
|---|---|---|
| `htmlspecialchars` の既定フラグ | `ENT_COMPAT`（`'` はそのまま） | `ENT_QUOTES \| ENT_SUBSTITUTE \| ENT_HTML401`（`'` → `&#039;`） |
| `htmlspecialchars` の既定文字コード | ISO-8859-1（バイト単位、何でも通る） | `default_charset`（既定 UTF-8） |
| `default_charset`（Content-Type の charset） | php.ini 次第（空なら charset なし） | UTF-8 |
| `mb_*` の既定エンコーディング | `mbstring.internal_encoding` | `default_charset`（`mbstring.internal_encoding` は 8.0 で削除） |

**EUC-JP / Shift_JIS のアプリで最も危険なのは htmlspecialchars**: 文字コード UTF-8 として不正なバイト列になるため、
`ENT_SUBSTITUTE` が付く既定では日本語が U+FFFD（UTF-8 の 3 バイト）に化け、付けなければ**空文字列**を返す。
画面の日本語がすべて消えるか化ける。

## 直し方
- `htmlspecialchars($s)` → `htmlspecialchars($s, ENT_COMPAT, 'EUC-JP')`（旧の既定フラグを明示）。ラッパー関数（`h()`）があればそこだけ直す。
- `mb_convert_kana($s, 's')` など、`mb_*` の第 n 引数にエンコーディングを明示する。
- `header('Content-Type: text/html; charset=EUC-JP')` を全画面の共通 include（設定ファイル）で送る。
  リダイレクトだけの画面（ログアウトなど）も共通 include を読むか、同じヘッダを送る。
- `null` を渡すと PHP 8.1 以降 Deprecated。未定義になりうる値はラッパー側で `(string)` にする。

## 落とし穴（分類案に書くもの）
- Content-Type に `charset=EUC-JP` が付くのは旧環境との差分（旧が `default_charset` 空なら `text/html` のみ）。意図した変更として人に上げる。
- `'EUC-JP'` を明示すると、**EUC-JP として不正なバイト列を含む入力**に対して htmlspecialchars は空文字列を返す（旧はそのまま出していた）。
  旧と完全に同じバイト列を出すなら `'ISO-8859-1'` 指定（ASCII 以外を素通し）だが、可読性のため `'EUC-JP'` を推奨し、差分として人に上げる。
- `strlen` はバイト数なので、EUC-JP のままなら変わらない（UTF-8 化（3D）で変わる）。

## 学び（実施記録）
- 2026-10-22-01: `h()` は `ENT_COMPAT` を明示して旧の出力（`'` をエスケープしない）を保った。既定のままだと `'` が `&#039;` になり、特性テスト 09, 16, 20 が差分になる（解答キー T20）。
