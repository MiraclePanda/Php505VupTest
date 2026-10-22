-- 商品管理システム スキーマ（移行先 DB。newapp/db/migrate.php が作成する）
-- 本番は Symfoware（ODBC 接続）。検証用に SQLite（ODBC ドライバ経由）で代用している
-- ODBC では 1 回に 1 文しか実行できないため、migrate.php が ; で分割して流す
-- 文字コード: UTF-8（移行後。旧 DB は EUC-JP のバイト列だった）

CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  name VARCHAR(50) NOT NULL DEFAULT ''
);

CREATE TABLE products (
  id INTEGER PRIMARY KEY,
  code VARCHAR(10) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL DEFAULT '',
  category_id INTEGER NOT NULL DEFAULT 0,
  price INTEGER NOT NULL DEFAULT 0,
  stock INTEGER NOT NULL DEFAULT 0,
  updated_at VARCHAR(19)
);
CREATE INDEX products_category_id ON products (category_id);

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  login_id VARCHAR(20) NOT NULL UNIQUE,
  password VARCHAR(32) NOT NULL DEFAULT '',
  name VARCHAR(50) NOT NULL DEFAULT ''
);
