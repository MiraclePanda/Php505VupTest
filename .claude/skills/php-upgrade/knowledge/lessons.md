# 学び（横断）

新しいものを上に書く。ID は L-連番。ルール固有の学びは `../rules/R*.md` の「学び」に書く。

## L-008 解答キーも php.ini と突き合わせて読む（2026-10-22-01）
- 状況: 解答キー B01 は再表示が `\'` になると書いていたが、旧環境は `magic_quotes_sybase = On` なので実際は `''`。B02 の「約 33 文字」も UTF-8 の計算で、EUC-JP では 50 文字。T13 の置換例は `D` 修飾子がなく、末尾の改行を通してしまう。
- 次から: 解答キー（実案件では仕様書や過去の障害票）の記述も、旧環境の実行設定で検算する。食い違いは `runs/` の「解答キーの更新候補」に書き、人に確認する。

## L-007 ソースの外の前提を棚卸しする（2026-10-22-01）
- 状況: ODBC の DSN 定義（T28）、列名の大文字小文字のドライバ依存（T27）を見逃した。どちらもソースを読むだけでは出てこない。
- 次から: 棚卸しで R14（実行環境）を必ず埋める。DB ドライバを替える前提なら、列名・型・件数の扱いを DB ラッパーで吸収する。
- 反映: `rules/R14-runtime-environment.md`（新規）、`rules/R09` の学び、`agents/upgrade-inventory.md`、`newapp/app/include/db.inc`（ATTR_CASE）

## L-006 「当時のバグ」と「対応不要」も一覧に載せる（2026-10-22-01）
- 状況: 存在しない ID で 200 のまま die する（B03）、`var` 宣言（T11）は、直す必要がないと判断して棚卸しに書かなかった。採点では見逃しと区別できない。人も「直さない」判断を確認できない。
- 次から: 直さないものも 1 行ずつ載せ、方針欄に「対応不要（理由）」と書く。

## L-005 ゴールデンがないときは、移行の前に期待値を書く（2026-10-22-01）
- 状況: 旧環境で特性テストを記録できなかった。`verify.sh` は PHP エラーの有無しか見ておらず、カテゴリ未指定の検索が 0 件になる回帰（PHP エラーなし）を「OK」と判定した。
- 次から: 棚卸しの直後に、旧の php.ini とコードから旧の応答を推定して `tests/characterization/expectations.tsv` に書く（`must` / `legacy`）。`verify.sh` が照合する。ゴールデンを記録したら食い違う行を直す。
- 反映: `php-upgrade/SKILL.md` の手順 1.5、`tests/characterization/check-expectations.py`、`verify.sh`

## L-004 テストケースはルールの落とし穴から起こす（2026-10-22-01）
- 状況: 既存の 22 ケースは、DB の文字コード（LIKE が壊れる）、比較規則（`"abc" == 0`）、ereg と preg の `$` の違いで結果が変わる入力を踏んでいなかった。R12 を適用しても全ケース同一で、効果を確かめられなかった。
- 次から: 棚卸しで見つけた「黙って壊れる」課題ごとに、それを踏む入力をテストに足す（1 文字の日本語、文字境界をまたぐ語、空・非数値のパラメータ、末尾に改行、項目の欠落）。
- 反映: `tests/characterization/run.sh`（18b, 23〜28）、`php-upgrade/SKILL.md` の手順 1.5

## L-003 適用順は「Fatal を先に」「うるさい失敗を静かにしない」（2026-10-22-01）
- 状況: ルール番号順に進めると Fatal が残ったまま何ステップも進み、画面単位の検証ができなかった。また、R09（プレースホルダ化）を R11（比較規則）より先にしたため、SQL エラーが 0 件に変わって PHP エラー検出から消えた。
- 次から: R01 → Fatal を出すもの（R06, R08, R04）→ 入力（R02, R03）→ クラス（R07）→ magic_quotes（R05）→ 比較（R11）→ DB（R09, R12）→ 文字コード（R10）→ 警告（R13）。
- 反映: 各ルールの `order`、`php-upgrade/SKILL.md` の「順序の注意」

## L-002 `php -l` が OK でも安心しない（2026-10-22-01）
- 状況: 移行前のアプリは PHP 8.5 の `php -l` で 3 ファイルしか NG にならなかったが、実際は全画面でソースが露出していた（短縮タグ部分が HTML 扱い）。
- 次から: 構文チェックに加えて、必ず新環境で HTTP リクエストを送り、応答にソースが出ていないかを見る（`verify.sh` の手順 5）。
- 反映: `lint.sh` の注意書き、`verify.sh`、`rules/R01`

## L-001 EUC-JP のソースは専用の道具で編集する（2026-10-22-01）
- 状況: Claude Code の Edit / Write は UTF-8 以外のファイルを拒否する（「Edit and Write will refuse it」）。sed や perl で直接書き換えると、日本語を含む行の置換で文字化けを起こしやすい。
- 次から: `scripts/upgrade/eucjp.py`（cat / replace / write / check）を使う。フックが newapp の変更ごとに文字コードを検査する。
- 反映: `scripts/upgrade/eucjp.py`、`hooks/guard.py`、`hooks/post-edit-lint.sh`

## 環境メモ（Claude Code のクラウドで実行する場合）
- Docker は `sudo dockerd > /tmp/dockerd.log 2>&1 &` で起動する。Docker Hub からの pull はできる。
- deb.debian.org に出られないため `docker/modern/Dockerfile` の apt-get が失敗する。`scripts/upgrade/build-modern-image.sh` がホスト（Ubuntu）の apt で .deb を取って展開するフォールバックを持つ。
- museum.php.net など旧 PHP のソース配布元にも出られないため、旧環境（PHP 5.0.5）のビルドとゴールデンの記録は手元の環境で行う。
