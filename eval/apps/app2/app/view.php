<?
/*
 * お知らせ詳細  パラメータ: id
 */
require_once("include/common.inc");
db_connect();
$notice = new Notice();

include("templates/header.tpl");
if (!call_user_method('load', $notice, $id)) {
    header("Location: index.php");
    exit;
}
?>
<h2><?=h(stripslashes($notice->title))?></h2>
<p>投稿日: <?=fmt_date($notice->created_at)?></p>
<div><?=nl2br(h(stripslashes($notice->body)))?></div>
<? if (array_key_exists('tags', $notice) && $notice->tags != "") { ?>
<p>タグ: <?=h(implode(" / ", split("[ ,]+", stripslashes($notice->tags))))?></p>
<? } ?>
<p><a href="index.php">一覧へ戻る</a></p>
<? include("templates/footer.tpl"); ?>
