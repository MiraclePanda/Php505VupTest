<?php
/*
 * 共通関数
 */

function h($str)
{
    return htmlspecialchars($str);
}

// 価格を表示用に整形して $row['price_disp'] に入れる
// ※呼び出し側で参照渡しすること format_price(&$row)
function format_price($row)
{
    $row['price_disp'] = number_format($row['price']) . "円";
}

// 商品コードの先頭2文字（分類記号）
function code_prefix($code)
{
    return $code{0} . $code{1};
}

// カテゴリ一覧を取得（名前順）
function get_categories()
{
    $cats = array();
    $result = db_query("SELECT id, name FROM categories");
    while ($row = mysql_fetch_assoc($result)) {
        $cats[$row['id']] = $row['name'];
    }
    uasort($cats, create_function('$a, $b', 'return strcmp($a, $b);'));
    return $cats;
}

// <option>タグを生成
function category_options($cats, $selected)
{
    $html = "";
    reset($cats);
    while (list($id, $name) = each($cats)) {
        $sel = ($id == $selected) ? " selected" : "";
        $html .= "<option value=\"" . $id . "\"" . $sel . ">" . h($name) . "</option>\n";
    }
    return $html;
}

// ログインチェック
function is_login()
{
    return session_is_registered("login_user");
}
?>
