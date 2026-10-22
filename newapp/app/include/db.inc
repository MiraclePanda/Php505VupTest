<?php
/*
 * DBアクセス共通関数（ODBC）
 *   旧: odbc_* を直接使い、SQL は呼び出し側で文字列連結していた（magic_quotes でエスケープされた値を埋め込む前提）。
 *   新: PDO_ODBC（例外モード）で接続し、値はすべてプレースホルダで渡す。
 *       odbc_execute() は「' で始まり ' で終わる値」をファイル名とみなして読む仕様があるため使わない。
 */

function db_connect()
{
    global $DB_DSN, $DB_USER, $DB_PASS;

    try {
        $conn = new PDO("odbc:" . $DB_DSN, $DB_USER, $DB_PASS);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        die("DB接続エラー: " . $e->getMessage());
    }
    return $conn;
}

// $params はプレースホルダ ? に順に対応する値の配列
function db_query($sql, $params = array())
{
    global $conn;

    try {
        $result = $conn->prepare($sql);
        $result->execute(array_values($params));
    } catch (PDOException $e) {
        die("SQLエラー: " . $e->getMessage() . "<br>" . $sql);
    }
    return $result;
}

// 1 行を連想配列で返す。行がなければ false（旧: odbc_fetch_array）
function db_fetch($result)
{
    return $result->fetch(PDO::FETCH_ASSOC);
}

// 1 行目の 1 列目を返す（旧: odbc_fetch_row + odbc_result($result, 1)）
function db_fetch_value($result)
{
    return $result->fetchColumn();
}

// 更新件数（旧: odbc_num_rows）
function db_affected($result)
{
    return $result->rowCount();
}
?>
