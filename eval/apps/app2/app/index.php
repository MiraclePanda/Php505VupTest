<?
/*
 * お知らせ一覧
 *   パラメータ: kw（キーワード）, page, sort（0 = 新しい順, title = 件名順）
 */
require_once("include/common.inc");
db_connect();

switch ($sort) {
case 0:
    $order = "created_at DESC, id DESC";
    break;
case "title":
    $order = "title, id";
    break;
default:
    $order = "created_at DESC, id DESC";
}

$where = "";
if (strlen($kw) > 0) {
    $where = " WHERE title LIKE " . q("%" . $kw . "%");
}
$cnt = db_rows("SELECT COUNT(*) AS cnt FROM notices" . $where);
$total = $cnt[0]['cnt'];
if (!ereg("^[0-9]+$", $page)) {
    $page = 1;
}
$pages = ceil($total / list_max);
$rows = db_rows("SELECT * FROM notices" . $where . " ORDER BY " . $order
    . " LIMIT " . LIST_MAX . " OFFSET " . (($page - 1) * LIST_MAX));
$kw_disp = stripslashes($kw);

include("templates/header.tpl");
?>
<form action="index.php" method="get">
キーワード: <input type="text" name="kw" value="<?=h($kw_disp)?>">
<input type="submit" value="検索">
</form>
<p>全 <?=$total?> 件</p>
<table>
<?
foreach ($rows as $row) {
    $label = $row['important'] ? "重要" : is_new($row['created_at']) ? "新着" : "通常";
    $title_html = h(stripslashes($row['title']));
    if ($kw_disp != "") {
        $title_html = eregi_replace(quotemeta(h($kw_disp)), "<b>\\0</b>", $title_html);
    }
    include("templates/list_row.tpl");
}
?>
</table>
<p>
<? for ($i = 1; $i <= $pages; $i++) { ?>
<a href="index.php?kw=<?=urlencode($kw_disp)?>&sort=<?=$sort?>&page=<?=$i?>"><?=$i?></a>
<? } ?>
</p>
<a href="post.php">新規投稿</a> | <a href="export.php">CSV出力</a>
<? include("templates/footer.tpl"); ?>
