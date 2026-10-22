<?php
/*
 * DB を初期化する（旧環境 PHP 5.0.5 / 新環境 PHP 8.5 の両方で動く書き方にしている）
 *   ODBC データソース経由で db/init/*.sql を流す。
 *   usage: php init.php [dbfile] [dsn]
 */
$file = isset($argv[1]) ? $argv[1] : "/var/www/data/shop.db";
$dsn  = isset($argv[2]) ? $argv[2] : "shop";

if (file_exists($file)) {
    unlink($file);
}
$conn = odbc_connect($dsn, "", "") or die("connect error: " . odbc_errormsg() . "\n");
foreach (array("01_schema.sql", "02_data.sql") as $name) {
    $sql = implode("", file(dirname(__FILE__) . "/init/" . $name));
    $sql = preg_replace('/^--.*$/m', '', $sql);
    // ODBC は 1 回に 1 文しか実行できないので ; で分割する
    foreach (explode(";", $sql) as $stmt) {
        if (trim($stmt) == "") {
            continue;
        }
        if (!odbc_exec($conn, $stmt)) {
            die($name . ": " . odbc_errormsg($conn) . "\n" . $stmt . "\n");
        }
    }
}
odbc_close($conn);
chmod($file, 0666);
echo "initialized: " . $file . "\n";
?>
