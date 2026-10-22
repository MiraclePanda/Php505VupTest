<?php
/*
 * DBアクセス共通関数（ODBC）
 *   旧: odbc_* を直接使い、SQL は呼び出し側で文字列連結していた（magic_quotes でエスケープされた値を埋め込む前提）。
 *   新: PDO_ODBC（例外モード）で接続し、値はすべてプレースホルダで渡す。
 *       odbc_execute() は「' で始まり ' で終わる値」をファイル名とみなして読む仕様があるため使わない。
 *   文字コード: DB は UTF-8、アプリは EUC-JP。SQL と値は送る前に DB_CHARSET へ、結果は APP_CHARSET へ変換する。
 */

function db_connect()
{
    global $DB_DSN, $DB_USER, $DB_PASS;

    try {
        $conn = new PDO("odbc:" . $DB_DSN, $DB_USER, $DB_PASS);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        die("DB接続エラー: " . db_to_app($e->getMessage()));
    }
    return $conn;
}

// $params はプレースホルダ ? に順に対応する値の配列
function db_query($sql, $params = array())
{
    global $conn;

    try {
        $result = $conn->prepare(app_to_db($sql));
        $result->execute(array_map('app_to_db', array_values($params)));
    } catch (PDOException $e) {
        die("SQLエラー: " . db_to_app($e->getMessage()) . "<br>" . $sql);
    }
    return $result;
}

// 1 行を連想配列で返す。行がなければ false（旧: odbc_fetch_array）
function db_fetch($result)
{
    $row = $result->fetch(PDO::FETCH_ASSOC);
    if ($row === false) {
        return false;
    }
    return array_map('db_to_app', $row);
}

// 1 行目の 1 列目を返す（旧: odbc_fetch_row + odbc_result($result, 1)）
function db_fetch_value($result)
{
    return db_to_app($result->fetchColumn());
}

// 更新件数（旧: odbc_num_rows）
function db_affected($result)
{
    return $result->rowCount();
}

// アプリの文字コード → DB の文字コード（文字列以外はそのまま）
function app_to_db($value)
{
    if (!is_string($value) || APP_CHARSET == DB_CHARSET) {
        return $value;
    }
    return mb_convert_encoding($value, DB_CHARSET, APP_CHARSET);
}

// DB の文字コード → アプリの文字コード（文字列以外はそのまま）
function db_to_app($value)
{
    if (!is_string($value) || APP_CHARSET == DB_CHARSET) {
        return $value;
    }
    return mb_convert_encoding($value, APP_CHARSET, DB_CHARSET);
}
?>
