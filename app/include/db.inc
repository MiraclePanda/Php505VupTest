<?php
/*
 * DBアクセス共通関数（SQLite）
 */

function db_connect()
{
    global $DB_FILE;

    $conn = @sqlite_open($DB_FILE, 0666, $sqlite_error) or die("DB接続エラー: " . $sqlite_error);
    return $conn;
}

function db_query($sql)
{
    global $conn;

    $result = @sqlite_query($conn, $sql);
    if (!$result) {
        die("SQLエラー: " . sqlite_error_string(sqlite_last_error($conn)) . "<br>" . $sql);
    }
    return $result;
}
?>
