<?
/*
 * お知らせの削除（管理者のみ）  パラメータ: id
 */
require_once("../include/common.inc");

if ($PHP_AUTH_USER != $ADMIN_USER || $PHP_AUTH_PW != $ADMIN_PASS) {
    header('WWW-Authenticate: Basic realm="admin"');
    header('HTTP/1.0 401 Unauthorized');
    echo "認証が必要です。";
    exit;
}
db_connect();
db_exec("DELETE FROM notices WHERE id = " . $id);
header("Location: ../index.php");
?>
