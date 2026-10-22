<?php
/*
 * 共通関数
 */

function h($str)
{
    return htmlspecialchars($str);
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
    while (odbc_fetch_row($result)) {
        $cats[odbc_result($result, "id")] = odbc_result($result, "name");
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
