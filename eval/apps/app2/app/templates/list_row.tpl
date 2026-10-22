<tr>
<td><?=$row['id']?></td>
<td><?=$label?></td>
<td><a href="view.php?id=<?=$row['id']?>"><?=$title_html?></a></td>
<td><?=fmt_date($row['created_at'])?></td>
</tr>
