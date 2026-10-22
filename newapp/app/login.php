<?php
/*
 * ログイン画面
 */
require_once("include/config.inc");
require_once("include/db.inc");
require_once("include/functions.inc");

session_start();
$conn = db_connect();

// 旧: register_globals で POST の値がそのまま変数になっていた
$login_id = request_var('login_id');
$password = request_var('password');
// 旧: ログイン失敗時だけ代入され、それ以外は未定義だった
$error = null;

if ($_SERVER['REQUEST_METHOD'] == "POST") {
    $sql = "SELECT * FROM users"
         . " WHERE login_id = '" . $login_id . "'"
         . " AND password = '" . md5($password) . "'";
    $result = db_query($sql);
    if (odbc_fetch_row($result)) {
        // 旧: session_register("login_user") + グローバル変数 $login_user への代入
        $_SESSION['login_user'] = odbc_result($result, "name");
        header("Location: index.php");
        exit;
    }
    $error = "ログインIDまたはパスワードが違います。";
}

include("include/header.inc");
?>
<h2>ログイン</h2>
<?php if ($error) { ?>
<p class="error"><?=$error?></p>
<?php } ?>
<form method="post" action="login.php">
<table>
<tr><th>ログインID</th><td><input type="text" name="login_id" value="<?=h($login_id)?>"></td></tr>
<tr><th>パスワード</th><td><input type="password" name="password"></td></tr>
</table>
<input type="submit" value="ログイン">
</form>
<?php
include("include/footer.inc");
?>
