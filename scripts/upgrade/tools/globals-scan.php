<?php
/*
 * register_globals 依存の候補を洗い出す。
 *   グローバルスコープ（関数・クラスの外）で、代入より先に使われている変数を列挙する。
 *   register_globals = On の環境では、こうした変数は GET / POST / Cookie / セッションから値が入りうる。
 *
 *   usage: php -d short_open_tag=1 globals-scan.php <dir_or_file>...
 *   出力: TSV（file, line, var, kind）
 *     kind: read          代入前に読んでいる（入力値に依存している可能性が高い）
 *           isset         isset/empty で存在確認している（入力値の可能性が高い）
 *           append        代入前に追記している（$a[] = / .= / += など。外部から初期値を注入できる）
 *           conditional   if などの中でしか代入されていないのに、外で読んでいる（未定義のまま使われる経路がある）
 *           include-scope include される断片で未定義（呼び出し元で定義されているか要確認）
 *
 *   ヒューリスティックなので誤検出・見逃しがある。結果は棚卸しの「候補」として扱い、目視で確定すること。
 */
if (!ini_get('short_open_tag')) {
    fwrite(STDERR, "short_open_tag=1 で実行してください（短縮タグのファイルを PHP として読むため）\n");
    exit(2);
}
$ignore = array('this', 'GLOBALS', '_GET', '_POST', '_COOKIE', '_SERVER', '_ENV', '_FILES', '_REQUEST',
    '_SESSION', 'argv', 'argc', 'php_errormsg', 'http_response_header');

$files = array();
foreach (array_slice($argv, 1) as $t) {
    if (is_dir($t)) {
        $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($t, FilesystemIterator::SKIP_DOTS));
        foreach ($it as $f) {
            if (preg_match('/\.(php|inc|phtml)$/', $f->getFilename())) {
                $files[] = $f->getPathname();
            }
        }
    } else {
        $files[] = $t;
    }
}
sort($files);

foreach ($files as $file) {
    $tokens = token_get_all(file_get_contents($file));
    $n = count($tokens);
    $isFragment = !preg_match('/\.php$/', $file);  // .inc は include される断片とみなす
    $depth = 0;            // 波括弧の深さ
    $scopeStack = array(); // 関数・クラス本体の開始深さ
    $pendingScope = false; // function/class キーワードから本体の { まで（引数リストを含む）
    $state = array();      // 変数名 => 'uncond'（無条件に代入済み） / 代入したときに開いていたブロックの列
    $blocks = array();     // 開いているブロックの ID の列
    $blockId = 0;
    $reported = array();
    for ($i = 0; $i < $n; $i++) {
        $t = $tokens[$i];
        if (is_array($t)) {
            if ($t[0] === T_FUNCTION || $t[0] === T_CLASS || $t[0] === T_INTERFACE) {
                $pendingScope = true;
            }
            if ($t[0] === T_CURLY_OPEN || $t[0] === T_DOLLAR_OPEN_CURLY_BRACES) {
                $depth++;
            }
            if ($t[0] !== T_VARIABLE || $scopeStack || $pendingScope) {
                continue;
            }
            $name = substr($t[1], 1);
            if (in_array($name, $ignore) || preg_match('/^HTTP_\w+_VARS$/', $name) || isset($reported[$name])) {
                continue;
            }
            $kind = classify($tokens, $i);
            if ($kind === null && nextSig($tokens, $i) === '=' && readsSelfInRhs($tokens, $i, $t[1])
                && !isset($state[$name])) {
                $kind = 'read';  // $id = (int)$id; のように右辺で自分を読んでいる
            }
            if ($kind === null) {
                // 制御構造の中（$depth > 0）での代入は「条件付き」
                if ($depth === 0) {
                    $state[$name] = 'uncond';
                } elseif (!isset($state[$name]) || $state[$name] !== 'uncond') {
                    $state[$name] = $blocks;
                }
                continue;
            }
            if (isset($state[$name]) && ($state[$name] === 'uncond'
                    || array_slice($blocks, 0, count($state[$name])) === $state[$name])) {
                continue;  // 無条件に代入済み、または代入したブロックの内側で読んでいる
            }
            if (isset($state[$name])) {
                $kind = 'conditional';
            } elseif ($isFragment && $kind === 'read') {
                $kind = 'include-scope';
            }
            $reported[$name] = true;
            echo $file, "\t", $t[2], "\t$", $name, "\t", $kind, "\n";
            continue;
        }
        if ($t === '{') {
            $depth++;
            $blocks[] = ++$blockId;
            if ($pendingScope) {
                $scopeStack[] = $depth;
                $pendingScope = false;
            }
        } elseif ($t === '}') {
            if ($scopeStack && end($scopeStack) === $depth) {
                array_pop($scopeStack);
            }
            $depth--;
            array_pop($blocks);
        } elseif ($t === ';') {
            $pendingScope = false;  // 抽象メソッドなど本体のない宣言
        }
    }
}

// $tokens[$i] が代入の左辺のとき、右辺（; まで）に同じ変数が現れるか
function readsSelfInRhs($tokens, $i, $var)
{
    $paren = 0;
    for ($j = $i + 1; $j < count($tokens) && $tokens[$j] !== ';' && $tokens[$j] !== '{'; $j++) {
        if (is_array($tokens[$j]) && $tokens[$j][0] === T_CLOSE_TAG) {
            break;
        }
        if ($tokens[$j] === '(') {
            $paren++;
        } elseif ($tokens[$j] === ')' && --$paren < 0) {
            break;  // while ($row = f()) の閉じ括弧
        }
        if (is_array($tokens[$j]) && $tokens[$j][0] === T_VARIABLE && $tokens[$j][1] === $var) {
            return true;
        }
    }
    return false;
}

// 変数の最初の出現がどういう使われ方かを判定する。代入なら null
function classify($tokens, $i)
{
    $prev = prevSig($tokens, $i);
    $next = nextSig($tokens, $i);
    // foreach (... as $k => $v) / global $x / static $x / catch (E $e)
    if (is_array($prev) && in_array($prev[0], array(T_AS, T_GLOBAL, T_STATIC, T_DOUBLE_ARROW))) {
        return null;
    }
    if ($prev === '&' ) {
        return null;  // 参照渡しの引数（呼び出し先で代入される想定）
    }
    // list($a, $b) = ...
    if (inList($tokens, $i)) {
        return null;
    }
    if ($next === '=') {
        return null;
    }
    if ($next === '[') {
        // $a[...] = は「未初期化の配列に追記」
        $j = skipBrackets($tokens, nextIndex($tokens, $i));
        $after = $tokens[$j] ?? null;
        if ($after === '=') {
            return 'append';
        }
    }
    if (is_array($next) && in_array($next[0], array(T_CONCAT_EQUAL, T_PLUS_EQUAL, T_MINUS_EQUAL, T_MUL_EQUAL,
            T_DIV_EQUAL, T_OR_EQUAL, T_AND_EQUAL, T_INC, T_DEC))) {
        return 'append';
    }
    if (is_array($prev) && in_array($prev[0], array(T_INC, T_DEC))) {
        return 'append';
    }
    // isset($x) / empty($x)
    $p2 = prevSig($tokens, prevIndex($tokens, $i));
    if ($prev === '(' && is_array($p2) && in_array($p2[0], array(T_ISSET, T_EMPTY))) {
        return 'isset';
    }
    return 'read';
}

function nextIndex($tokens, $i)
{
    for ($j = $i + 1; $j < count($tokens); $j++) {
        if (!is_array($tokens[$j]) || !in_array($tokens[$j][0], array(T_WHITESPACE, T_COMMENT, T_DOC_COMMENT))) {
            return $j;
        }
    }
    return count($tokens);
}

function prevIndex($tokens, $i)
{
    for ($j = $i - 1; $j >= 0; $j--) {
        if (!is_array($tokens[$j]) || !in_array($tokens[$j][0], array(T_WHITESPACE, T_COMMENT, T_DOC_COMMENT))) {
            return $j;
        }
    }
    return -1;
}

function nextSig($tokens, $i)
{
    $j = nextIndex($tokens, $i);
    return $tokens[$j] ?? null;
}

function prevSig($tokens, $i)
{
    $j = prevIndex($tokens, $i);
    return $j >= 0 ? $tokens[$j] : null;
}

// $tokens[$j] が '[' のとき、対応する ']' の次の有意トークンの位置を返す
function skipBrackets($tokens, $j)
{
    $d = 0;
    for (; $j < count($tokens); $j++) {
        if ($tokens[$j] === '[') {
            $d++;
        } elseif ($tokens[$j] === ']') {
            $d--;
            if ($d === 0) {
                $k = nextIndex($tokens, $j);
                if (($tokens[$k] ?? null) === '[') {
                    return skipBrackets($tokens, $k);
                }
                return $k;
            }
        }
    }
    return $j;
}

// list( ... $i ... ) = の中にあるか
function inList($tokens, $i)
{
    $d = 0;
    for ($j = $i - 1; $j >= 0; $j--) {
        $t = $tokens[$j];
        if ($t === ')') {
            $d++;
        } elseif ($t === '(') {
            if ($d === 0) {
                $p = prevSig($tokens, $j);
                return is_array($p) && $p[0] === T_LIST;
            }
            $d--;
        } elseif ($t === ';' || $t === '{' || $t === '}') {
            return false;
        }
    }
    return false;
}
