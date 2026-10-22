<?php
/*
 * DB の LIKE が、非 UTF-8（EUC-JP など）のバイト列のまま格納された文字列を正しく検索できるかを調べる。
 *   列の値の部分文字列（1〜3 文字）と JIS 第 1 水準の全漢字を検索語にして、DB の LIKE の結果を
 *   PHP での文字単位の検索（ASCII のみ大文字小文字を無視）と比べる。
 *
 *   usage: php like-charset-check.php <PDO DSN> <table> <id列> <文字列列> [文字コード=EUC-JP]
 *   例) php like-charset-check.php "odbc:Driver=SQLite3;Database=/var/www/data/legacy.db" products id name
 *
 *   見逃し（文字単位では含むのに LIKE でヒットしない）と誤ヒットが 0 でなければ、
 *   DB の文字コードを変えるか、検索方法を変える必要がある（ルール R12）。
 *   参考として、バイト単位の検索（SQLite 2 など文字コードを解釈しない DB の挙動）との違いも出す。
 */
list(, $dsn, $table, $idCol, $col) = $argv + array(null, null, null, null, null);
$enc = $argv[5] ?? 'EUC-JP';
if (!$col) {
    fwrite(STDERR, "usage: php like-charset-check.php <PDO DSN> <table> <id列> <文字列列> [文字コード]\n");
    exit(2);
}
$p = new PDO($dsn);
$p->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$rows = $p->query("SELECT $idCol, $col FROM $table")->fetchAll(PDO::FETCH_KEY_PAIR);

$terms = array();
foreach ($rows as $v) {
    $chars = mb_str_split((string)$v, 1, $enc);
    for ($i = 0; $i < count($chars); $i++) {
        for ($l = 1; $l <= 3 && $i + $l <= count($chars); $l++) {
            $terms[implode('', array_slice($chars, $i, $l))] = true;
        }
    }
}
if (strtoupper($enc) === 'EUC-JP') {
    for ($a = 0xB0; $a <= 0xCF; $a++) {
        for ($b = 0xA1; $b <= 0xFE; $b++) {
            $terms[chr($a) . chr($b)] = true;
        }
    }
}
$st = $p->prepare("SELECT $idCol FROM $table WHERE $col LIKE ?");
$miss = $false = $byteDiff = 0;
$examples = array();
foreach (array_keys($terms) as $t) {
    $t = (string)$t;
    if (strpbrk($t, '%_') !== false) {
        continue;
    }
    $st->execute(array("%$t%"));
    $got = $st->fetchAll(PDO::FETCH_COLUMN);
    $char = $byte = array();
    foreach ($rows as $id => $v) {
        if (mb_stripos((string)$v, $t, 0, $enc) !== false) { $char[] = $id; }
        if (strpos(strtolower((string)$v), strtolower($t)) !== false) { $byte[] = $id; }
    }
    sort($got); sort($char); sort($byte);
    if ($byte != $char) { $byteDiff++; }
    if ($got == $char) { continue; }
    count(array_diff($char, $got)) ? $miss++ : $false++;
    if (count($examples) < 5) {
        $examples[] = sprintf("  %s: LIKE=[%s] 文字単位=[%s]", mb_convert_encoding($t, 'UTF-8', $enc),
            implode(',', $got), implode(',', $char));
    }
}
printf("検索語 %d 件: LIKE の見逃し %d 件、誤ヒット %d 件（参考: バイト単位の検索が文字単位と食い違う語 %d 件）\n",
    count($terms), $miss, $false, $byteDiff);
echo implode("\n", $examples), $examples ? "\n" : "";
exit($miss + $false ? 1 : 0);
