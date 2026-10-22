<?
/*
 * お知らせ一覧の CSV 出力（Excel で開くので Shift_JIS のまま）
 */
require_once("include/common.inc");
?>

<?
db_connect();
$rows = db_rows("SELECT id, title, created_at FROM notices ORDER BY id");
header("Content-Type: text/csv; charset=Shift_JIS");
header("Content-Disposition: attachment; filename=notices.csv");
foreach ($rows as $row) {
    echo implode(array($row['id'], stripslashes($row['title']), $row['created_at']), ",") . "\r\n";
}
?>
