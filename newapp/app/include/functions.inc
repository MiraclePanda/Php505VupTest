<?php
/*
 * 共通関数
 */

// 旧 PHP（7 以前）が「文字列と数値の比較」で文字列を数値にした規則を再現する（先頭の数値部分。なければ 0）。
// PHP 8 では数値でない文字列と数値の == は文字列比較になり、"" == 0 や "abc" == 0 が偽になるため
function legacy_num($value)
{
    return is_numeric($value) ? $value + 0 : (float)$value;
}

// リクエストパラメータを取り出す（旧: register_globals = On で自動的にグローバル変数になっていた）
// 旧環境の variables_order = "EGPCS" と同じく、Cookie > POST > GET の順に後勝ちで探す。なければ null
function request_var($name)
{
    foreach (array($_COOKIE, $_POST, $_GET) as $src) {
        if (isset($src[$name])) {
            return $src[$name];
        }
    }
    return null;
}

// POST の値を取り出す。なければ null（旧: $HTTP_POST_VARS['x'] の未定義キーは E_NOTICE を抑止して null だった）
function post_var($name)
{
    return isset($_POST[$name]) ? $_POST[$name] : null;
}

function h($str)
{
    // 旧の既定（ENT_COMPAT、文字コード指定なし）に合わせる。PHP 8 の既定は ENT_QUOTES | ENT_SUBSTITUTE、
    // 文字コード UTF-8 で、EUC-JP の日本語が化ける。null は旧と同じく空文字（PHP 8.1 以降 null は Deprecated）
    return htmlspecialchars((string)$str, ENT_COMPAT, 'EUC-JP');
}

// 価格を表示用に整形して $row['price_disp'] に入れる
// ※参照渡しで受ける（旧: 呼び出し側の実行時参照渡し format_price(&$row) に頼っていた）
function format_price(&$row)
{
    $row['price_disp'] = number_format($row['price']) . "円";
}

// 商品コードの先頭2文字（分類記号）
function code_prefix($code)
{
    // 旧: $code{0} . $code{1}。範囲外は旧環境では Notice（非表示）で空文字だったので、警告の出ない substr で同じ結果にする
    return substr($code, 0, 2);
}

// カテゴリ一覧を取得（名前順）
function get_categories()
{
    $cats = array();
    $result = db_query("SELECT id, name FROM categories");
    while ($row = db_fetch($result)) {
        $cats[$row['id']] = $row['name'];
    }
    uasort($cats, 'compare_category_name');
    return $cats;
}

// get_categories() の並べ替え用（旧: create_function で作っていた比較関数）
function compare_category_name($a, $b)
{
    return strcmp($a, $b);
}

// <option>タグを生成
function category_options($cats, $selected)
{
    $html = "";
    foreach ($cats as $id => $name) {
        // 旧: $id == $selected（整数と入力文字列の比較）。旧の比較規則で判定する
        $sel = ($id == legacy_num($selected)) ? " selected" : "";
        $html .= "<option value=\"" . $id . "\"" . $sel . ">" . h($name) . "</option>\n";
    }
    return $html;
}

// ログインチェック
function is_login()
{
    // 旧: session_is_registered("login_user")。値が null でも登録済みなら true だったので isset ではなく array_key_exists
    return isset($_SESSION) && array_key_exists('login_user', $_SESSION);
}
?>
