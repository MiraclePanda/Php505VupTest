---
name: php-upgrade
description: PHP 5.x（register_globals / magic_quotes 時代）のアプリを PHP 8.5 へ移行する。棚卸し → ルールごとの移行と検証 → 差分の分類 → レポートまでを、newapp/ に出力しながら進める。「PHP 8.5 に上げて」「移行して」「アップグレードを実施」で使う。
---

# PHP 5.x → 8.5 移行（オーケストレーション）

`docs/upgrade-process.md` のフェーズ 1〜3C を、エージェントとスクリプトで実行する手順。
移行元（`app/`）は**読むだけ**で、結果はすべて `newapp/` に出す。

## 始める前に必ず読むもの

1. `CLAUDE.md`（作業ルール）と `docs/upgrade-process.md`（プロセス）
2. `knowledge/lessons.md`（過去の実施で分かったこと。**ここに書いてある失敗を繰り返さない**）
3. `rules/README.md` とルールカタログ `rules/R*.md`（検出パターン、直し方、落とし穴）
4. `docs/known-differences.md`（承認済みの差分）

`docs/sample-app-traps.md` は評価用の解答キー。**移行中は読まない**（フックで拒否される）。採点は `upgrade-retro` スキルで行う。

## 道具

| 道具 | 用途 |
|---|---|
| `scripts/upgrade/init.sh` | `app/` を `newapp/app/` にバイト単位で複写し、`newapp/docs/` にテンプレートを置く |
| `scripts/upgrade/inventory.sh` | 機械検出（旧 php.ini、php -l、register_globals 候補、ルール別 grep）を Markdown で出力 |
| `scripts/upgrade/eucjp.py` | **EUC-JP ファイルの読み書き**。Edit / Write は UTF-8 以外を扱えないので必ずこれを使う |
| `scripts/upgrade/lint.sh` | PHP 8.5 で `php -l`（Deprecated も失敗扱い） |
| `scripts/upgrade/scan.py --rule Rnn` | ルール 1 つの残件確認 |
| `scripts/upgrade/verify.sh <label>` | 構文・文字コード・新環境での特性テスト・PHP エラー検出・前ステップとの差分 |
| フック（`.claude/settings.json`） | app/ と golden/ の書き換え拒否、解答キーの参照拒否、newapp 変更後の自動 lint |

## 手順

### 0. 準備
- Docker が動くこと（クラウドでは `sudo dockerd > /tmp/dockerd.log 2>&1 &`）。新環境イメージは `verify.sh` が必要に応じて `build-modern-image.sh` でビルドする。
- 作業ブランチを切る。`scripts/upgrade/init.sh` を実行し、そのままコミット（「移行元を複写」）。
- 移行前のアプリを新環境で動かしたスナップショットを取る: `APP_DIR=app scripts/upgrade/verify.sh 00-original`（壊れ方の記録。NG で正常）。

### 1. 棚卸し（エージェント `upgrade-inventory`）
- `scripts/upgrade/inventory.sh app > newapp/docs/inventory-raw.md` の結果と、全ソースの目視から `newapp/docs/inventory.md` を書く。
- 各課題に: ルール ID（なければ `NEW-n` として新ルール案）、場所、症状（Fatal / 黙って壊れる / 警告 / 差分のみ）、直し方の方針、**人の判断が要るか**。
- 「エラーにならずに結果が変わる」課題（PHP4 コンストラクタ、比較規則、magic_quotes の副作用、文字コード）を特に探す。`php -l` と grep で拾えるものは半分程度しかない前提で、全ファイルを 1 行ずつ読む。
- コミット: 「棚卸し」

### 2. ルールごとの移行（`upgrade-migrator` → `upgrade-verifier` → `upgrade-reviewer`）
ルールカタログの `order` 順に、棚卸しで該当があったルールを 1 つずつ処理する。1 ルールにつき:

1. **移行**（`upgrade-migrator`）: そのルールの該当箇所だけを `newapp/app/` で直す。`eucjp.py` で編集する。他のルールの課題には触らない。
2. **検証**（`upgrade-verifier`）: `scripts/upgrade/verify.sh Rnn` を実行し、結果を報告する。
   - 構文エラー・文字コード違反は移行に差し戻す。
   - 途中のルールでは PHP エラーが残っていてよい（後のルールで消える）。ただし**このルールで新たに増えたエラー**は差し戻す。
   - 前ステップから変わったケースを列挙し、それぞれ「このルールで直るはずのもの」か「意図しない変化」かを判定する。
3. **意味のレビュー**（`upgrade-reviewer`）: コミット前の差分を、旧環境の php.ini と PHP 5.0 の意味で読み、振る舞いが同じかを確認する。ゴールデンがない間は**ここが主な安全網**。
4. コミット: `[Rnn] <ルール名>`。本文に、直した場所、検証結果（verify の要約）、人の判断が要る点。

順序の注意:
- R01（短縮タグ）を最初に。これが残っているとソースが出力され、他の検証が意味をなさない。
- R05（magic_quotes）と R09（DB のプレースホルダ化）は同時に効かせないと、`'` を含む入力で SQL エラーになる中間状態ができる。R05 では表示側の `stripslashes` だけ外し、SQL 側は R09 で直す。中間状態の差分は検証で「R09 で直る」と記録する。
- R12（DB の文字コード）はデータ移行スクリプト `newapp/db/migrate.php` と DB ラッパーの変換を同じコミットにする。

### 3. 差分の分類（人に上げる）
- ゴールデン（旧環境の記録）があれば `compare.sh` の差分、なければ「旧環境ならこう出たはず」という推定との差分を、`newapp/docs/diff-classification.md` に書く。
- 分類案: **回帰**（直す）/ **仕様変更候補**（旧のバグや危険な挙動が直ったもの、文字コードの明示など）/ **環境差**（エラー文言など）。
- **自分で承認しない。** `docs/known-differences.md` には人が承認したものだけを書く。

### 4. 受け入れ確認とレポート
- `scripts/upgrade/verify.sh final` が RESULT: OK（PHP エラーなし）。
- `python3 scripts/upgrade/scan.py newapp/app` で残件を確認し、残すものは理由を書く（detect は広めなので、正しい書き方も拾う）。
- `newapp/docs/migration-report.md` を書く: 適用したルールとコミット、検証結果、人の判断が要る点、未確認事項（ゴールデンがないなど）、所要時間とつまずき。

### 5. 振り返り（`upgrade-retro` スキル）
移行が終わったら必ず実行する。採点（解答キーとの突き合わせ）と、`knowledge/` と `rules/` への学びの反映を行う。
**次回の精度はここで決まる。**

## 判断の原則
- 旧の挙動を保つのが既定。旧の挙動がバグや脆弱性でも、互換移行では原則そのまま残し、直すなら改善（3E）として別コミット・別 PR にする。
- ただし、旧の挙動が**実行設定（magic_quotes、register_globals）の副作用**で、再現すると不自然なコードになるもの（例: 再表示で `'` が二重になる）は、再現せずに「仕様変更候補」として上げる。どちらにしたかは必ずレポートに書く。
- 迷ったら、両案とその影響をレポートの「人の判断が要る点」に書き、推奨案で進める。
