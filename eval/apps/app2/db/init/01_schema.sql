-- 社内お知らせ掲示板 スキーマ
-- 本番は Symfoware（ODBC 接続）。検証用に SQLite（ODBC ドライバ経由）で代用している
-- ODBC では 1 回に 1 文しか実行できないため、db/init.php が ; で分割して流す
-- 文字コード: Shift_JIS（CP932。バイト列のまま格納）

CREATE TABLE notices (
  id INTEGER PRIMARY KEY,
  title VARCHAR(60) NOT NULL DEFAULT '',
  body TEXT,
  tags VARCHAR(100),
  important INTEGER NOT NULL DEFAULT 0,
  created_at VARCHAR(19)
);
