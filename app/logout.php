<?
/*
 * ログアウト
 */
session_start();
session_unregister("login_user");
session_destroy();
header("Location: index.php");
?>
