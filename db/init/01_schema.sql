-- 商品管理システム スキーマ（MySQL 4.1 当時の書き方）
SET NAMES utf8;

DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

CREATE TABLE categories (
  id int(11) NOT NULL auto_increment,
  name varchar(50) NOT NULL default '',
  PRIMARY KEY (id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE products (
  id int(11) NOT NULL auto_increment,
  code varchar(10) NOT NULL default '',
  name varchar(100) NOT NULL default '',
  category_id int(11) NOT NULL default '0',
  price int(11) NOT NULL default '0',
  stock int(11) NOT NULL default '0',
  updated_at datetime default NULL,
  PRIMARY KEY (id),
  UNIQUE KEY code (code),
  KEY category_id (category_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE users (
  id int(11) NOT NULL auto_increment,
  login_id varchar(20) NOT NULL default '',
  password varchar(32) NOT NULL default '',
  name varchar(50) NOT NULL default '',
  PRIMARY KEY (id),
  UNIQUE KEY login_id (login_id)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
