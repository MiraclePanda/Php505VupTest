---
name: upgrade-retro
description: PHP 移行の実施後に振り返りを行い、採点と学びの蓄積をする。解答キー（またはテスト結果・レビュー指摘）と突き合わせて見逃し・誤修正を洗い出し、.claude/skills/php-upgrade/ の rules と knowledge を更新する。「振り返り」「採点」「ノウハウを反映」で使う。
---

# 移行の振り返り（採点と学びの反映）

`php-upgrade` による移行が**完了してから**実行する。移行中に実行しない（解答キーを見ると評価が無効になる）。

## 1. 材料を集める
- 移行レポート `newapp/docs/migration-report.md`、棚卸し `newapp/docs/inventory.md`、差分の分類案 `newapp/docs/diff-classification.md`
- 移行のコミット列（`git log --oneline <base>..HEAD`）
- 正解の情報源:
  - サンプルアプリ: 解答キー `docs/sample-app-traps.md`。読む前に `mkdir -p .work && touch .work/allow-answer-key` で参照ロックを解除し、**終わったら必ず `rm .work/allow-answer-key`**
  - 実案件: 本番障害、受け入れテストの不具合、人のレビュー指摘、承認された差分

## 2. 採点
解答キーの各項目について、次を判定して表にする（`runs/<実施 ID>.md`）。
- 棚卸しで検出したか（inventory.md に該当する行があるか）→ **検出率**
- 正しく直したか、または差分として正しく分類したか → **修正率**
- 振る舞いを誤って変えた変更（回帰）→ **誤修正**
- 解答キーにない課題を見つけていれば「追加発見」として記録する（解答キー側の更新候補）。

## 3. 原因分析と反映
見逃し・誤修正の 1 件ずつに、「なぜ起きたか」と「次はどう防ぐか」を書き、反映先を決めて**実際に直す**。
| 原因 | 反映先 |
|---|---|
| grep で拾えるのにパターンがなかった | `rules/Rnn.md` の `detect` |
| 拾えない種類（文脈依存） | 棚卸しの観点（`agents/upgrade-inventory.md`）、`scripts/upgrade/tools/` に検出器を追加 |
| 直し方を誤った | `rules/Rnn.md` の「直し方」「落とし穴」、`agents/upgrade-reviewer.md` の観点 |
| 手順・順序の問題 | `php-upgrade/SKILL.md` の手順、`knowledge/lessons.md` |
| 道具の不足・不具合 | `scripts/upgrade/` |

反映後、`python3 scripts/upgrade/scan.py app` で、追加した detect が移行元の該当箇所を拾うことを確かめる。

## 4. 記録
- `knowledge/runs/<実施 ID>.md`: 採点表、原因分析、反映した変更の一覧
- `knowledge/metrics.md`: 1 行追加
- `knowledge/lessons.md`: 横断的な学び（L-連番）
- 振り返りの変更は移行のコミットと分けて 1 コミットにする（「振り返り: <実施 ID>」）。
