# 移行パイプラインの評価（評価者専用。移行エージェントに見せない）

`scripts/upgrade/make-eval-copy.sh` はこのディレクトリを複製に含めない。

| ファイル | 内容 |
|---|---|
| `checks.tsv` | 解答キー（`docs/sample-app-traps.md`）の項目ごとの客観チェック。コード（newapp/app）・棚卸し（inventory.md）・DB 移行の有無を正規表現で見る |
| `score.py` | `checks.tsv` と隠しテスト（このリポジトリの特性テスト 29 ケースと expectations.tsv）で、評価用の複製の移行結果を採点する |

## サンプルアプリ

| アプリ | 内容 | 解答キー |
|---|---|---|
| app1（リポジトリ直下の `app/`） | 商品管理、EUC-JP、magic_quotes_sybase=On | `docs/sample-app-traps.md`、`eval/checks.tsv` |
| `eval/apps/app2` | 社内お知らせ掲示板、CP932、magic_quotes_sybase=Off、output_buffering 依存、DB に magic_quotes の残骸 | `eval/apps/app2/traps.md`、`checks.tsv`、隠しテスト `hidden/` |

## 手順

```sh
scripts/upgrade/make-eval-copy.sh /tmp/eval/runNN [--app eval/apps/app2]   # 答えの見えない複製
# 複製の中でエージェントに移行させる（php-upgrade スキルの「エージェント分割での実行」）
python3 eval/score.py /tmp/eval/runNN [--app eval/apps/app2]              # 採点（隠しテストは Docker で実行）
```

自動採点は機械的に判定できる部分だけ。最終的な検出率・修正率は、score.py の出力を見ながら人（または評価者の Claude）が
解答キーと突き合わせて決め、`.claude/skills/php-upgrade/knowledge/metrics.md` に記録する。

**注意:** 同じサンプルアプリで繰り返し評価すると、蓄積したノウハウ（lessons.md、rules/）がこのアプリに過学習する。
別の課題を仕込んだ第 2 のサンプルアプリでの評価（汎化の確認）を定期的に行うこと。
