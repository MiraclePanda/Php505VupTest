<?php
/*
 * 商品管理システム 設定ファイル
 * Last modified: 2005/09/12
 */

// DB接続情報（ODBC データソース名）
$DB_DSN  = "shop";
$DB_USER = "";
$DB_PASS = "";

define("APP_TITLE", "商品管理システム");
define("PAGE_SIZE", 5);

// 画面の文字コード。旧は default_charset が空で Content-Type に charset が付かなかったが、
// PHP 8 は default_charset = UTF-8 で「charset=UTF-8」を付けてしまうため、EUC-JP を明示する
header("Content-Type: text/html; charset=EUC-JP");
?>
