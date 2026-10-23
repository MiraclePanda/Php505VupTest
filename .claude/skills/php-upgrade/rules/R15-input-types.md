---
id: R15
title: 文字列を期待する入力に配列が来ても Fatal にしない
phase: 3B
category: 意味が変わった仕様
order: 75
detect:
  - '\b(strlen|mb_\w+|trim|str_\w+|substr|strto\w+|preg_\w+|htmlspecialchars|md5|sha1|urlencode|explode)\s*\(\s*\$'
  - '\$_(GET|POST|REQUEST|COOKIE)\['
  - '\bfunction\s+(request|post|get)_var\b'
---
## 何が起きるか
- `?keyword[]=x`、`name[]=x` のように、文字列を期待するパラメータに配列が送られることがある（操作ミス、攻撃、古いブラウザの拡張）。
- 旧（PHP 5.0）は関数ごとに黙って処理を続けた。`strlen(array)` は `"Array"` として 5、`mb_convert_kana(array)` は Warning なしで null、
  文字列連結は `"Array"`（Notice は 5.4 から）。
- **PHP 8 では内部関数の引数の型が厳密になり、`strlen()`・`mb_*()`・`trim()` などに配列を渡すと TypeError（Fatal）。**
  連結や `(string)` は `Array to string conversion` の Warning（R13 の方針に反する）。
- 正常な画面操作では起きないので、特性テストにも期待値にも出てこない。意味レビュー（2026-10-22-02）で初めて見つかった。

## 直し方
- 入力の取り出し口（R03 で作るヘルパー `request_var()` / `post_var()` など）で、配列が来たら**未指定（null）として扱う**。
  ```php
  function scalar_input($value) { return is_array($value) ? null : $value; }
  ```
  旧の挙動は関数ごとにまちまち（"Array" で保存、全件一覧、SQL エラー）で再現に意味がないため、未指定に揃えて**仕様変更候補**として上げる。
- 本当に配列を受けるパラメータ（`ids[]` など）は、専用の取り出し関数で `is_array` を確かめてから使う。
- ヘルパーを通さずに `$_GET['x']` などを直接使っている箇所が残っていないか、detect で確認する。

## 落とし穴
- R03 でヘルパーを作るときに一緒に入れるのが最も安い。後から入れる場合は、ヘルパーを通らない入力（`$_SERVER['PHP_AUTH_USER']`、Cookie）も確認する。
- `preg_match('/^[0-9]+$/', $page)` のように、配列を想定して `is_string()` で守っている箇所は、ヘルパーで null にすれば不要になるが、残しても害はない。
- 巨大な数値（`page=99999999999999999999`）は配列とは別の問題。`(int)` は PHP 8.5 で「表せない float」の Warning を出す（R13）。
  旧と同じく SQL エラーになるなら差分なし、Warning が出るなら回帰として扱う。

## 確認方法
- 特性テストに、検索語・絞り込み・ログイン・更新の各フォームで `name[]=x` を送るケースを入れる（`tests/characterization/run.sh` の 29〜33）。
- `verify.sh` の「PHP のエラー・警告」が 0 であること。

## 学び（実施記録）
- 2026-10-22-02: run02（エージェント分割）の意味レビューで、`edit.php` に `name[]=x` を送ると `strlen()` の TypeError で Fatal になる、
  `?keyword[]=x` で `mb_convert_kana()` が Fatal になる、と指摘された。1 回目の移行（newapp）も同じだった。
  1 回目の差分の分類案（D12）は「仕様変更候補」として上げていたが、Fatal は回帰として直すべきもの。ルールにしていなかったため棚卸しの観点から漏れた。
