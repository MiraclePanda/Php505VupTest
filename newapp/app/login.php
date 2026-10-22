<?
/*
 * ログイン画面
 */
require_once("include/config.inc");
require_once("include/db.inc");
require_once("include/functions.inc");

session_start();
$conn = db_connect();

if ($HTTP_SERVER_VARS['REQUEST_METHOD'] == "POST") {
    $sql = "SELECT * FROM users"
         . " WHERE login_id = '" . $login_id . "'"
         . " AND password = '" . md5($password) . "'";
    $result = db_query($sql);
    if (odbc_fetch_row($result)) {
        session_register("login_user");
        $login_user = odbc_result($result, "name");
        header("Location: index.php");
        exit;
    }
    $error = "ログインIDまたはパスワードが違います。";
}

include("include/header.inc");
?>
<h2>ログイン</h2>
<? if ($error) { ?>
<p class="error"><?=$error?></p>
<? } ?>
<form method="post" action="login.php">
<table>
<tr><th>ログインID</th><td><input type="text" name="login_id" value="<?=h(stripslashes($login_id))?>"></td></tr>
<tr><th>パスワード</th><td><input type="password" name="password"></td></tr>
</table>
<input type="submit" value="ログイン">
</form>
<?
include("include/footer.inc");
?>
