<?php
/*
 * 旧環境（PHP 5.0.5 / SQLite 2）の DB を初期化する
 *   usage: php init_legacy.php [dbfile]
 */
$file = isset($argv[1]) ? $argv[1] : "/var/www/data/shop.db";
if (file_exists($file)) {
    unlink($file);
}
$db = sqlite_open($file, 0666, $err) or die("open error: " . $err . "\n");
foreach (array("01_schema.sql", "02_data.sql") as $name) {
    $sql = implode("", file(dirname(__FILE__) . "/init/" . $name));
    if (!sqlite_exec($db, $sql)) {
        die($name . ": " . sqlite_error_string(sqlite_last_error($db)) . "\n");
    }
}
sqlite_close($db);
chmod($file, 0666);
echo "initialized: " . $file . "\n";
?>
