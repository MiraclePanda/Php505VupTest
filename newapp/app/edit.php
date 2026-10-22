<?php
/*
 * 商品編集画面
 *   GET  : id の商品を表示
 *   POST : 入力チェックの上、更新して一覧へ戻る
 */
require_once("include/config.inc");
require_once("include/db.inc");
require_once("include/functions.inc");
require_once("include/Product.class.php");

session_start();
if (!is_login()) {
    header("Location: login.php");
    exit;
}
$conn = db_connect();
$categories = get_categories();
$id = (int)$id;

if ($HTTP_SERVER_VARS['REQUEST_METHOD'] == "POST") {
    $product = new Product();
    $product->id          = $id;
    $product->code        = $HTTP_POST_VARS['code'];
    $product->name        = $HTTP_POST_VARS['name'];
    $product->category_id = $HTTP_POST_VARS['category_id'];
    $product->price       = $HTTP_POST_VARS['price'];
    $product->stock       = $HTTP_POST_VARS['stock'];

    if ($product->validate($categories)) {
        $product->save();
        header("Location: index.php?msg=updated");
        exit;
    }
    $errors = $product->errors;
} else {
    $product = Product::find($id);
    if (!$product) {
        die("商品が見つかりません。");
    }
}

include("include/header.inc");
?>
<h2>商品編集</h2>

<?php if (count($errors) > 0) { ?>
<ul class="error">
<?php foreach ($errors as $err) { ?>
<li><?=$err?></li>
<?php } ?>
</ul>
<?php } ?>

<form method="post" action="edit.php?id=<?=$id?>">
<table>
<tr><th>商品コード</th><td><input type="text" name="code" value="<?=h($product->code)?>" size="10"></td></tr>
<tr><th>商品名</th><td><input type="text" name="name" value="<?=h($product->name)?>" size="40"></td></tr>
<tr><th>カテゴリ</th><td><select name="category_id"><?=category_options($categories, $product->category_id)?></select></td></tr>
<tr><th>価格</th><td><input type="text" name="price" value="<?=h($product->price)?>" size="10"> 円</td></tr>
<tr><th>在庫数</th><td><input type="text" name="stock" value="<?=h($product->stock)?>" size="10"></td></tr>
</table>
<input type="submit" value="更新">
<a href="index.php">一覧へ戻る</a>
</form>
<?php
include("include/footer.inc");
?>
