---
id: R03
title: register_globals 依存の除去
phase: 3A
category: 実行設定依存
order: 30
detect:
  - 'extract\(\s*\$_(GET|POST|REQUEST|COOKIE|SERVER)'
  - 'import_request_variables'
---
## 何が起きるか
`register_globals` は PHP 5.4 で削除。リクエストパラメータ・Cookie・セッション変数が自動でグローバル変数にならないため、
**値が常に未定義（null）になり、エラーにならずに機能が黙って壊れる**（検索条件が効かない、ログインできない等）。

## 検出
正規表現では拾えない。`scripts/upgrade/tools/globals-scan.php` を使う（`scripts/upgrade/inventory.sh` が実行する）。
グローバルスコープで代入前に読まれている変数が候補。kind の意味:
- `read` / `isset`: 入力値として使っている可能性が高い。どこから来る値か（GET / POST / Cookie / セッション / サーバ変数）を画面の form や link から特定する。
- `conditional`: if の中でしか代入されていない。旧環境では外部から値を注入できた（`?errors[]=...` など）。新環境では未定義 → **初期化する**。
- `include-scope`: include される断片で未定義。呼び出し元で定義されているか、セッション変数（R04）かを確認する。

## 直し方
1. 入力値はファイル先頭で明示的に取り出して変数に入れる。どの配列から取るかは旧環境の `variables_order`（既定 `EGPCS`、後勝ち）に合わせる。
   画面の form が GET なのに POST でも受け付けていた、という挙動を変えたくない場合は、後勝ち順を再現するヘルパーを使う:
   ```php
   // variables_order = "EGPCS" の register_globals と同じ優先順位（C > P > G）
   function request_var($name) {
       foreach (array($_COOKIE, $_POST, $_GET) as $src) {
           if (isset($src[$name])) { return $src[$name]; }
       }
       return null;
   }
   ```
2. 条件付きでしか代入されない変数は、使う前に初期化する（`$errors = array();` `$error = "";`）。
3. セッション変数がグローバルとして使われている箇所は `$_SESSION['name']` に置き換える（R04）。

## 落とし穴
- 未定義の値は旧環境では null。`isset()` で判定している箇所はそのまま null を返すヘルパーで同じ結果になる。
- 配列パラメータ（`?a[]=1`）が来ると、旧環境でも新環境でも配列が入る。文字列前提の関数（`trim` など）に渡ると PHP 8 では TypeError で Fatal になる。互換移行ではヘルパーの戻り値を変えずに残し、改善で型を検査する（判断が要る場合は人に上げる）。
- 「注入できた」挙動（`?error=<script>` が表示される等）は初期化で消える。セキュリティ上の改善だが、互換移行で必ず起きる差分として分類案に書く。
- `$_REQUEST` を使うと PHP 8 の `request_order`（既定 "GP"）に左右され、Cookie が入らない。旧の挙動と揃えるならヘルパーを使う。
