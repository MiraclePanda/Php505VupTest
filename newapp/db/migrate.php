<?php
/*
 * データ移行（3C）: 旧 DB（EUC-JP のバイト列）→ 新 DB（UTF-8）
 *   新 DB にスキーマ（schema.sql）を作り、旧 DB の全行を文字コードを変換して入れ、件数とハッシュで突き合わせる。
 *
 *   usage: php migrate.php <旧 DB の ODBC DSN> <新 DB の ODBC DSN> [新 DB のファイル（SQLite のとき。あれば作り直す）]
 *   例) php migrate.php "Driver=SQLite3;Database=/var/www/data/legacy.db" shop /var/www/data/shop.db
 *
 *   本番（Symfoware）では、旧 DB と新 DB の両方に ODBC で届く場所で実行する。
 *   変換できない文字（機種依存文字など）があれば中止する。
 */
const SRC_CHARSET = 'EUC-JP';
const DST_CHARSET = 'UTF-8';
// 移行するテーブルと、突き合わせの並び順に使う主キー
const TABLES = array('categories' => 'id', 'products' => 'id', 'users' => 'id');

if ($argc < 3) {
    fwrite(STDERR, "usage: php migrate.php <旧 DSN> <新 DSN> [新 DB ファイル]\n");
    exit(2);
}
list(, $srcDsn, $dstDsn) = $argv;
$dstFile = $argv[3] ?? null;

function connect($dsn)
{
    $pdo = new PDO('odbc:' . $dsn);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    return $pdo;
}

function convert_row($row, $from, $to, $where)
{
    foreach ($row as $k => $v) {
        if (!is_string($v)) {
            continue;
        }
        if (!mb_check_encoding($v, $from)) {
            throw new RuntimeException("$where.$k: $from として不正なバイト列: " . bin2hex($v));
        }
        $c = mb_convert_encoding($v, $to, $from);
        if (mb_convert_encoding($c, $from, $to) !== $v) {
            throw new RuntimeException("$where.$k: $to との往復で元に戻らない: " . bin2hex($v));
        }
        $row[$k] = $c;
    }
    return $row;
}

function table_digest($pdo, $table, $key, $convertFrom = null)
{
    $h = hash_init('sha256');
    $n = 0;
    foreach ($pdo->query("SELECT * FROM $table ORDER BY $key") as $row) {
        $row = array_change_key_case($row, CASE_LOWER);
        if ($convertFrom) {
            // 新 DB の値を旧の文字コードに戻して比べる（旧と同じバイト列に戻ることの確認）
            $row = convert_row($row, $convertFrom, SRC_CHARSET, $table);
        }
        hash_update($h, serialize($row));
        $n++;
    }
    return array($n, hash_final($h));
}

try {
    if ($dstFile && file_exists($dstFile)) {
        unlink($dstFile);
    }
    $src = connect($srcDsn);
    $dst = connect($dstDsn);

    $schema = preg_replace('/^--.*$/m', '', file_get_contents(__DIR__ . '/schema.sql'));
    foreach (explode(';', $schema) as $stmt) {
        if (trim($stmt) !== '') {
            $dst->exec($stmt);
        }
    }

    $ok = true;
    foreach (TABLES as $table => $key) {
        $dst->beginTransaction();
        $ins = null;
        foreach ($src->query("SELECT * FROM $table ORDER BY $key") as $row) {
            $row = convert_row(array_change_key_case($row, CASE_LOWER), SRC_CHARSET, DST_CHARSET, $table);
            if (!$ins) {
                $cols = array_keys($row);
                $ins = $dst->prepare("INSERT INTO $table (" . implode(', ', $cols) . ") VALUES ("
                    . implode(', ', array_fill(0, count($cols), '?')) . ")");
            }
            $ins->execute(array_values($row));
        }
        $dst->commit();

        list($srcN, $srcHash) = table_digest($src, $table, $key);
        list($dstN, $dstHash) = table_digest($dst, $table, $key, DST_CHARSET);
        $match = $srcN === $dstN && $srcHash === $dstHash;
        $ok = $ok && $match;
        printf("%-12s 旧 %4d 行 / 新 %4d 行  内容の突き合わせ: %s\n", $table, $srcN, $dstN, $match ? 'OK' : 'NG');
    }
    if ($dstFile) {
        chmod($dstFile, 0666);
    }
    if (!$ok) {
        fwrite(STDERR, "突き合わせに失敗しました\n");
        exit(1);
    }
    echo "migrated: $srcDsn -> $dstDsn\n";
} catch (Exception $e) {
    fwrite(STDERR, "移行エラー: " . $e->getMessage() . "\n");
    exit(1);
}
