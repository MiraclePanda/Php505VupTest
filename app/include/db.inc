<?php
/*
 * DBアクセス共通関数
 */

function db_connect()
{
    global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME;

    $conn = @mysql_connect($DB_HOST, $DB_USER, $DB_PASS) or die("DB接続エラー: " . mysql_error());
    mysql_select_db($DB_NAME, $conn) or die("DB選択エラー: " . mysql_error());
    return $conn;
}

function db_query($sql)
{
    global $conn;

    $result = mysql_query($sql, $conn);
    if (!$result) {
        die("SQLエラー: " . mysql_error() . "<br>" . $sql);
    }
    return $result;
}
?>
