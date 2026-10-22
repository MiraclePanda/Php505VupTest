<?php
/*
 * ログアウト
 */
require_once("include/config.inc");

session_start();
unset($_SESSION['login_user']);
session_destroy();
header("Location: index.php");
?>
