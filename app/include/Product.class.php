<?php
/*
 * 商品クラス
 */
class Product
{
    var $id;
    var $code;
    var $name;
    var $category_id;
    var $price;
    var $stock;
    var $errors;

    function Product($row = null)
    {
        $this->errors = array();
        if ($row) {
            $this->id          = $row['id'];
            $this->code        = $row['code'];
            $this->name        = $row['name'];
            $this->category_id = $row['category_id'];
            $this->price       = $row['price'];
            $this->stock       = $row['stock'];
        }
    }

    // Product::find($id) で呼び出す
    function find($id)
    {
        $result = db_query("SELECT * FROM products WHERE id = " . $id);
        if (mysql_num_rows($result) == 0) {
            return false;
        }
        return new Product(mysql_fetch_assoc($result));
    }

    function validate($categories)
    {
        $this->errors = array();

        if (!ereg("^[A-Z]{2}-[0-9]{4}$", $this->code)) {
            $this->errors[] = "商品コードは「AA-9999」の形式で入力してください。";
        }
        if ($this->name == "") {
            $this->errors[] = "商品名を入力してください。";
        } elseif (strlen($this->name) > 100) {
            $this->errors[] = "商品名が長すぎます。";
        }
        if (!array_key_exists($this->category_id, $categories)) {
            $this->errors[] = "カテゴリを選択してください。";
        }
        if (!ereg("^[0-9]+$", $this->price)) {
            $this->errors[] = "価格は半角数字で入力してください。";
        }
        if (!ereg("^[0-9]+$", $this->stock)) {
            $this->errors[] = "在庫数は半角数字で入力してください。";
        }
        return count($this->errors) == 0;
    }

    function save()
    {
        $sql = "UPDATE products SET"
             . " code = '$this->code',"
             . " name = '$this->name',"
             . " category_id = $this->category_id,"
             . " price = $this->price,"
             . " stock = $this->stock,"
             . " updated_at = NOW()"
             . " WHERE id = $this->id";
        db_query($sql);
        return mysql_affected_rows();
    }
}
?>
