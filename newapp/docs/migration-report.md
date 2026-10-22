# 移行レポート

- 実施 ID: 2026-10-22-01（初回）
- 移行元 / 移行先: `app/` → `newapp/app/`（DB 移行は `newapp/db/`）
- 実施: Claude Code（`php-upgrade` スキルの手順に沿って実行。エージェントの役割は 1 つのセッションで順に担当）
- 所要時間: 1 セッション（自動化基盤の作成と同時に実施したため、移行だけの時間は測っていない）

## 結果

| 項目 | 結果 |
|---|---|
| PHP 8.5 構文チェック（`lint.sh`、Deprecated も失敗扱い） | OK（10 ファイル） |
| E_ALL で Warning / Deprecated / Notice なし（応答とエラーログ） | OK（29 ケース） |
| 旧環境の挙動の推定（`expectations.tsv`）との照合 | must 39 件すべて一致。legacy（旧の推定）との差分 3 件は分類案 D1〜D3 |
| 旧環境（ゴールデン）との比較 | **未実施**（ゴールデン未記録） |
| データ移行（件数と内容のハッシュ） | OK（3 テーブル 17 行） |
| ルール残件（`scan.py newapp/app`） | 33 件の候補が残るが、すべて正しい書き方（`var`、`count($this->errors)`、`htmlspecialchars(..., 'EUC-JP')` など）を detect が広めに拾ったもの |

## 適用したルールとコミット

順序は「Fatal を先に消して画面が動く状態を早く作る」方針で決めた（R01 → R06 → R08 → R04 → R02 → R03 → R07 → R05 → R09 → R10 → R12 → R11 → R13）。

| ルール | 変更箇所 | 検証で変わったケース |
|---|---|---|
| R01 短縮タグ | 5 ファイル 27 箇所 | 全ケース（ソース露出 → Parse error が表に） |
| R06 削除された構文 | `format_price` の参照渡し（定義側）、`$s{0}`、`=& new`、`(integer)` | 全ケース（Parse error → session_* の Fatal） |
| R08 削除された関数 | ereg ×4（`D` 修飾子 + is_string）、split、create_function、each | 全ケース |
| R04 セッション | `session_*` → `$_SESSION`、header.inc の `$login_user` | 全ケース（Fatal 解消） |
| R02 旧スーパーグローバル | `$HTTP_*_VARS`、`$PHP_SELF` | ログイン・更新が動く |
| R03 register_globals | `request_var()`（Cookie > POST > GET）、`$errors` `$error` の初期化 | 検索条件が効く。`'` を含む検索が SQL エラー（中間状態） |
| R07 PHP 4 クラス | `__construct`、`static find` | 編集画面 |
| R05 magic_quotes | 表示用 `stripslashes` の除去 | なし |
| R09 DB | `db.inc` を PDO_ODBC + プレースホルダに。画面の `odbc_*` をなくす | 09（`'` を含む検索）、19（更新）が成功 |
| R10 文字コード | `h()`、`mb_convert_kana`、Content-Type | 日本語の表示と検索が動く。PHP エラーが 0 に |
| R12 DB の文字コード | DB を UTF-8 に移行（`migrate.php`）、`db.inc` で変換 | 既存 22 ケースでは変化なし → ケース追加（23〜28） |
| R11 比較規則 | `legacy_num()`、カテゴリの絞り込みと selected 判定 | 05, 06, 26, 27（カテゴリ未指定で 0 件だった回帰が解消） |
| R13 警告 | `post_var()`、`array_key_exists((string)...)` | 18b |

振り返り（解答キーとの突き合わせ）の後に 1 件追加: R09 `PDO::ATTR_CASE = CASE_LOWER`（列名の大文字小文字をドライバに依存させない。SQLite では全ケース同一）。

テストの追加（移行とは別コミット）: 境界ケース 23〜28、項目欠落 18b、期待値 `expectations.tsv`。

## 人の判断が要る点

1. **DB の文字コード**（D14）: 推奨は UTF-8 + アプリとの境界で変換。SQLite 3 に EUC-JP のまま入れると、LIKE が商品名の部分文字列などで見逃し 115 件・誤ヒット 1349 件（`scripts/upgrade/tools/like-charset-check.php`）。
2. **Content-Type の charset**（D1）: 推奨は `charset=EUC-JP` を付ける。
3. **`'` を含むパスワード**（D5）: 本番にありうるか。ありうるなら旧の照合を再現する互換ロジックが要る。
4. **タイムゾーン**（D13）: 旧サーバの TZ。
5. **仕様変更候補 D2, D3, D6〜D9, D11, D12** の承認。

## 未確認事項・リスク

- **ゴールデン未記録**。旧環境との一致は推定（`expectations.tsv` とコードの読み合わせ）でしか確認していない。旧環境でゴールデンを記録し、`verify.sh` を再実行すること。
- 3A（旧環境での前倒し修正）は旧環境がないため実施せず、直接 PHP 8.5 で検証した。DB ラッパーは 3A の `odbc_prepare` 版を経ずに PDO_ODBC で実装した（PDO は PHP 5.1 以降なので旧環境では動かない）。
- 本番の Symfoware では未検証: 数値列への文字列バインド（D15）、LIKE の大文字小文字、列の長さ（UTF-8 化でバイト数が増える）。
- 改善（3E）は未実施: XSS（N1, N2）、MD5 パスワード・セッション固定（N3）、CSRF（N4）、`include/` の公開（N5）。

## つまずき（振り返りの材料）

- `php -l` は短縮タグのファイルを素通りさせる。R01 を最初に直すまで、どの検証も意味をなさなかった。
- ルールの番号順に適用すると、Fatal が残ったまま何ステップも進み、画面単位の検証ができない。Fatal を出すルールを先にした。
- **PHP エラーが出ない回帰（カテゴリ未指定で 0 件）を `verify.sh` が見逃した。** ゴールデンがないと「エラーがない = 正しい」になってしまう。期待値ファイルを足して検出できるようにした。
- 既存の特性テストは、DB の文字コード・比較規則・ereg の違いで結果が変わる入力を踏んでいなかった。ルールの「落とし穴」からテストケースを起こす手順が要る。
- R09 の detect は複数行に分かれた SQL の連結を拾えなかった（棚卸し中に追加）。
- `eucjp.py` の `--all` の位置、`migrate.php` の PDO 既定 fetch モード（数値キーが列名になる）で小さな手戻り。
