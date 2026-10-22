<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
<title><?=APP_TITLE?></title>
<style type="text/css">
body { font-family: sans-serif; font-size: 13px; }
table.list { border-collapse: collapse; }
table.list th, table.list td { border: 1px solid #999; padding: 3px 6px; }
table.list th { background: #ddeeff; }
.msg { color: #008800; }
.error { color: #cc0000; }
</style>
</head>
<body>
<h1><a href="index.php"><?=APP_TITLE?></a></h1>
<div class="nav">
<?php if (is_login()) { ?>
ログイン中: <?=h($_SESSION['login_user'])?> さん | <a href="logout.php">ログアウト</a>
<?php } else { ?>
<a href="login.php">ログイン</a>
<?php } ?>
</div>
<hr>
