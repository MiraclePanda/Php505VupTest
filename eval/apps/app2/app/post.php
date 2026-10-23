<?
/*
 * お知らせの新規投稿
 */
require_once("include/common.inc");
db_connect();

$errors = array();
if ($HTTP_SERVER_VARS['REQUEST_METHOD'] == "POST") {
    if (trim($title) == "") {
        $errors[] = "件名を入力してください。";
    } elseif (mb_strlen(stripslashes($title)) > 30) {
        $errors[] = "件名は30文字以内で入力してください。";
    }
    if (count($errors) == 0) {
        $important = $important ? 1 : 0;
        db_exec("INSERT INTO notices (title, body, tags, important, created_at) VALUES ("
            . q($title) . ", " . q($body) . ", " . q($tags) . ", " . $important . ", '" . date("Y-m-d H:i:s") . "')");
        $title_disp = h(stripslashes($title));
        $done = true;
    }
}

include("templates/header.tpl");
?>
<h2>新規投稿</h2>
<? if ($done) { ?>
<p><? echo "「${title_disp}」を登録しました。"; ?></p>
<p><a href="index.php">一覧へ</a></p>
<? } else { ?>
<? foreach ($errors as $e) { ?><p class="error"><?=$e?></p><? } ?>
<form action="post.php" method="post">
件名: <input type="text" name="title" value="<?=h(stripslashes($title))?>"><br>
本文: <textarea name="body"><?=h(stripslashes($body))?></textarea><br>
タグ: <input type="text" name="tags" value="<?=h(stripslashes($tags))?>"><br>
<input type="checkbox" name="important" value="1">重要
<input type="submit" value="投稿">
</form>
<? } ?>
<? include("templates/footer.tpl"); ?>
