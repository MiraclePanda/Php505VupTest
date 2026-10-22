---
id: R02
title: 旧スーパーグローバル（$HTTP_*_VARS, $PHP_SELF）
phase: 3A
category: 実行設定依存
order: 20
detect:
  - '\$HTTP_(GET|POST|COOKIE|SERVER|ENV|SESSION|POST_FILES)_VARS'
  - '\$PHP_SELF\b'
  - '\$HTTP_RAW_POST_DATA'
---
## 何が起きるか
`register_long_arrays` は PHP 5.4 で削除。`$HTTP_GET_VARS` などは未定義変数になり、PHP 8 では Warning + null。
`$PHP_SELF` は register_globals による `$_SERVER['PHP_SELF']` のコピーなので、これも未定義になる。

## 直し方
| 旧 | 新 |
|---|---|
| `$HTTP_GET_VARS` | `$_GET` |
| `$HTTP_POST_VARS` | `$_POST` |
| `$HTTP_COOKIE_VARS` | `$_COOKIE` |
| `$HTTP_SERVER_VARS` | `$_SERVER` |
| `$HTTP_ENV_VARS` | `$_ENV` |
| `$HTTP_SESSION_VARS` | `$_SESSION` |
| `$HTTP_POST_FILES` | `$_FILES` |
| `$PHP_SELF` | `$_SERVER['PHP_SELF']` |
| `$HTTP_RAW_POST_DATA` | `file_get_contents('php://input')` |

## 落とし穴
- 関数の中で `global $HTTP_POST_VARS;` としている箇所は、`global` 宣言ごと消す（スーパーグローバルは宣言不要）。
- 旧配列の値は magic_quotes 済み。R05 と合わせて扱う。
- 存在しないキーの参照は PHP 8 で Warning。`isset()` で守るかヘルパー経由にする（R13）。
- `$PHP_SELF` をそのまま出力している箇所は XSS（PATH_INFO 経由）だが、互換移行ではそのまま残し、改善（3E）で直す。
