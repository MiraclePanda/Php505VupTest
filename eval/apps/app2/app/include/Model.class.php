<?php
/*
 * テーブル 1 行を表す基底クラス
 */
class Model
{
    var $table;

    function Model($table)
    {
        $this->table = $table;
    }

    // id の行を読み込んでプロパティに入れる。なければ false
    function load($id)
    {
        $rows = db_rows("SELECT * FROM " . $this->table . " WHERE id = " . $id);
        if (count($rows) == 0) {
            return false;
        }
        foreach ($rows[0] as $k => $v) {
            $this->$k = $v;
        }
        $this->loaded = true;
        return true;
    }
}
?>
