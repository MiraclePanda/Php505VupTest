# Php505VupTest

PHP 5.0.5 で作られたアプリケーションを、Claude Code を使って PHP 8.5 へアップグレードするプロセスを確立するための検証用リポジトリ。

- [アップグレードプロセス](docs/upgrade-process.md)
- [サンプルアプリに仕込んだ移行課題（解答キー）](docs/sample-app-traps.md)
- [既知の差分](docs/known-differences.md)

## サンプルアプリ（`app/`）

2005 年頃の典型的な書き方で作った小さな商品管理システム。文字コードは EUC-JP。
本番の想定 DB は Symfoware（ODBC 接続）で、検証では SQLite の ODBC ドライバで代用している。

EUC-JP のファイルの差分を読むには、一度だけ次を実行する。

```sh
git config diff.eucjp.textconv "iconv -f EUC-JP -t UTF-8"
```

| 画面 | 内容 |
|---|---|
| `index.php` | 商品検索（キーワード、カテゴリ、ページング） |
| `login.php` / `logout.php` | ログイン（admin / admin123） |
| `edit.php` | 商品の編集・更新（要ログイン） |

## 使い方

```sh
# 旧環境: PHP 5.0.5 + Apache 2.0 + ODBC + SQLite 2 → http://localhost:8050/
docker compose -f docker/compose.legacy.yml up -d --build

# 新環境: PHP 8.5 + Apache 2.4 + ODBC + SQLite 3 → http://localhost:8085/
docker compose -f docker/compose.modern.yml up -d --build

# 特性テスト
scripts/reset-db.sh legacy
tests/characterization/run.sh http://localhost:8050 tests/characterization/golden
scripts/reset-db.sh modern
tests/characterization/run.sh http://localhost:8085 tests/characterization/actual
tests/characterization/compare.sh
```

旧環境のビルドでは、Docker が museum.php.net（PHP 5.0.5）と archive.apache.org（Apache 2.0.65）からソースを取得し、
Debian etch 上でコンパイルする。初回は数分かかる。
