<?php
/*
 * DBアクセス共通関数（ODBC）
 */

function db_connect()
{
    global $DB_DSN, $DB_USER, $DB_PASS;

    $conn = @odbc_connect($DB_DSN, $DB_USER, $DB_PASS) or die("DB接続エラー: " . odbc_errormsg());
    return $conn;
}

function db_query($sql)
{
    global $conn;

    $result = @odbc_exec($conn, $sql);
    if (!$result) {
        die("SQLエラー: " . odbc_errormsg($conn) . "<br>" . $sql);
    }
    return $result;
}
?>
