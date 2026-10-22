-- 商品管理システム スキーマ（SQLite 2.8 / PHP 5.0 の sqlite 拡張）
-- 本番は Symfoware。検証用に SQLite で代用している
-- 文字コード: EUC-JP（バイト列のまま格納）

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
