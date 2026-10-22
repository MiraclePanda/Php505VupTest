<?php
/*
 * 新環境（PHP 8.5 / SQLite 3）の DB を初期化する
 *   旧環境と同じ SQL（EUC-JP のバイト列）をそのまま投入し、
 *   「SQLite 2 のデータを無変換で SQLite 3 に移した状態」を再現する。
 *   usage: php init_modern.php [dbfile]
 */
$file = $argv[1] ?? '/var/www/data/shop.db';
if (file_exists($file)) {
    unlink($file);
}
$db = new PDO('sqlite:' . $file, options: [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
foreach (['01_schema.sql', '02_data.sql'] as $name) {
    $db->exec(file_get_contents(__DIR__ . '/init/' . $name));
}
$db = null;
chmod($file, 0666);
echo "initialized: {$file}\n";
