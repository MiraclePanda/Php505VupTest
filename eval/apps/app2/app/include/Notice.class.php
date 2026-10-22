<?php
/*
 * ‚¨’m‚ç‚¹
 */
class Notice extends Model
{
    var $id;
    var $title;
    var $body;
    var $tags;
    var $important;
    var $created_at;

    function Notice()
    {
        parent::Model("notices");
    }
}
?>
