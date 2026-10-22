<?php
/*
 * 社内お知らせ掲示板 共通設定・共通関数
 * 2005/10 総務部
 */

// DB（ODBC データソース名）
$DB_DSN = "shop";

// 管理者（削除画面の Basic 認証）
$ADMIN_USER = "admin";
$ADMIN_PASS = "secret";

define("SITE_NAME", "社内お知らせ掲示板");
define("LIST_MAX", 3, true);

// クラスは include/クラス名.class.php に置く
function __autoload($class)
{
    require_once(dirname(__FILE__) . "/" . $class . ".class.php");
}

function db_connect()
{
    global $DB_DSN, $conn;
    $conn = odbc_connect($DB_DSN, "", "") or die("DB接続エラー");
    return $conn;
}

// SQL の文字列リテラルを作る。
// magic_quotes_gpc で ' が \' になって来るので、SQLite 用に '' に直す
function q($s)
{
    return "'" . str_replace("\\'", "''", $s) . "'";
}

function db_rows($sql)
{
    global $conn;
    $res = odbc_exec($conn, $sql) or die("SQLエラー: " . odbc_errormsg($conn));
    $rows = array();
    while ($row = odbc_fetch_array($res)) {
        $rows[] = $row;
    }
    return $rows;
}

function db_exec($sql)
{
    global $conn;
    odbc_exec($conn, $sql) or die("SQLエラー: " . odbc_errormsg($conn));
}

function h($s)
{
    return htmlspecialchars($s);
}

// 2005-09-01 09:00:00 → 2005/09/01
function fmt_date($ymdhis)
{
    return strftime("%Y/%m/%d", strtotime($ymdhis));
}

// 1 週間以内の投稿は「新着」
function is_new($ymdhis)
{
    return strtotime($ymdhis) > mktime() - 7 * 86400;
}
?>
