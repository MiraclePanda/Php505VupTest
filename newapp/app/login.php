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
    // 未指定のときは旧と同じく空文字で照合する（旧: '' を連結。null を渡すと = NULL になり意味が変わる）
    $sql = "SELECT * FROM users"
         . " WHERE login_id = ?"
         . " AND password = ?";
    $result = db_query($sql, array((string)$login_id, md5((string)$password)));
    $row = db_fetch($result);
    if ($row) {
        // 旧: session_register("login_user") + グローバル変数 $login_user への代入
        $_SESSION['login_user'] = $row['name'];
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
