---
id: R04
title: session_register 系 → $_SESSION
phase: 3A
category: 削除された関数
order: 40
detect:
  - '\bsession_(register|unregister|is_registered)\s*\('
  - '\$HTTP_SESSION_VARS'
---
## 何が起きるか
`session_register` / `session_unregister` / `session_is_registered` は PHP 5.4 で削除。呼び出すと Fatal error。
register_globals = On のときは、セッション変数がグローバル変数としても見えていた（`$login_user` など）。

## 直し方
| 旧 | 新 |
|---|---|
| `session_register("x"); $x = v;` | `$_SESSION['x'] = v;` |
| `session_is_registered("x")` | `array_key_exists('x', $_SESSION)`（値が null でも true を返していたため isset ではない） |
| `session_unregister("x")` | `unset($_SESSION['x']);` |
| グローバルの `$x`（セッション由来） | `$_SESSION['x']` |

## 落とし穴
- `session_register()` は「登録だけ」して、値はリクエスト終了時のグローバル変数の値が保存される。登録の後に代入している順序でも動いていた。
  置換後は代入した値がそのまま保存されるので、代入の位置を確認する。
- `session_is_registered()` は `session_start()` 前に呼ぶと false。置換後も `$_SESSION` が未定義だと Warning になるので、
  `session_start()` より前に呼ばれる経路がないか確認する。
- セッション変数を参照する include 断片（ヘッダなど）は globals-scan で `include-scope` として出る。
