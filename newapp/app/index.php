<?php
/*
 * 商品検索画面
 *   パラメータ: keyword, category, page, msg
 */
require_once("include/config.inc");
require_once("include/db.inc");
require_once("include/functions.inc");

session_start();
$conn = db_connect();

// 旧: register_globals で GET パラメータがそのまま変数になっていた
$page     = request_var('page');
$keyword  = request_var('keyword');
$category = request_var('category');
$msg      = request_var('msg');

// ereg の $ は末尾のみ。preg の $ は末尾の改行の前にもマッチするので D を付ける。
// 配列が来たとき ereg はマッチしなかったが preg_match は TypeError になるので is_string で守る
if (!isset($page) || !is_string($page) || !preg_match('/^[0-9]+$/D', $page) || $page < 1) {
    $page = 1;
}
$categories = get_categories();

// 検索条件の組み立て
$where = "1=1";
if ($keyword != "") {
    // 全角スペースも区切りとして扱う
    $keyword = trim(mb_convert_kana($keyword, "s"));
    $words = explode(" ", $keyword);
    for ($i = 0; $i < count($words); $i++) {
        if ($words[$i] == "") {
            continue;
        }
        $where .= " AND (p.name LIKE '%" . $words[$i] . "%' OR p.code LIKE '%" . $words[$i] . "%')";
    }
}
if ($category != 0) {
    $where .= " AND p.category_id = " . $category;
}

// 件数
$result = db_query("SELECT COUNT(*) FROM products p WHERE " . $where);
odbc_fetch_row($result);
$total = odbc_result($result, 1);
$max_page = ceil($total / PAGE_SIZE);
$offset = ($page - 1) * PAGE_SIZE;

// 一覧
$sql = "SELECT p.id AS id, p.code AS code, p.name AS name, p.price AS price, p.stock AS stock, c.name AS category_name"
     . " FROM products p LEFT JOIN categories c ON p.category_id = c.id"
     . " WHERE " . $where
     . " ORDER BY p.code"
     . " LIMIT " . PAGE_SIZE . " OFFSET " . $offset;
$result = db_query($sql);

$query_string = "keyword=" . urlencode(stripslashes($keyword)) . "&category=" . $category;

include("include/header.inc");
?>
<?php if ($msg == "updated") { ?>
<p class="msg">商品情報を更新しました。</p>
<?php } ?>

<form method="get" action="<?=$_SERVER['PHP_SELF']?>">
キーワード: <input type="text" name="keyword" value="<?=h(stripslashes($keyword))?>" size="30">
カテゴリ:
<select name="category">
<option value="">すべて</option>
<?=category_options($categories, $category)?>
</select>
<input type="submit" value="検索">
</form>

<?php if ($total == 0) { ?>
<p>「<?=stripslashes($keyword)?>」に該当する商品はありません。</p>
<?php } else { ?>
<p><?=$total?> 件中 <?=$offset + 1?>〜<?=min($offset + PAGE_SIZE, $total)?> 件を表示</p>
<table class="list">
<tr>
<th>記号</th><th>商品コード</th><th>商品名</th><th>カテゴリ</th><th>価格</th><th>在庫</th><?php if (is_login()) { ?><th>操作</th><?php } ?>
</tr>
<?php while ($row = odbc_fetch_array($result)) { format_price($row); ?>
<tr>
<td><?=code_prefix($row['code'])?></td>
<td><?=h($row['code'])?></td>
<td><?=h($row['name'])?></td>
<td><?=h($row['category_name'])?></td>
<td align="right"><?=$row['price_disp']?></td>
<td align="right"><?=$row['stock']?></td>
<?php if (is_login()) { ?><td><a href="edit.php?id=<?=$row['id']?>">編集</a></td><?php } ?>
</tr>
<?php } ?>
</table>

<div class="pager">
<?php if ($page > 1) { ?><a href="<?=$_SERVER['PHP_SELF']?>?<?=$query_string?>&page=<?=$page - 1?>">&lt;&lt; 前へ</a><?php } ?>
<?=$page?> / <?=$max_page?>
<?php if ($page < $max_page) { ?><a href="<?=$_SERVER['PHP_SELF']?>?<?=$query_string?>&page=<?=$page + 1?>">次へ &gt;&gt;</a><?php } ?>
</div>
<?php } ?>
<?php
include("include/footer.inc");
?>
