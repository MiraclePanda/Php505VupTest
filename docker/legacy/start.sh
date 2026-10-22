#!/bin/sh
# DB がなければ初期化してから Apache を起動する
[ -f /var/www/data/shop.db ] || /usr/local/php5/bin/php /var/www/db/init_legacy.php
exec /usr/local/apache2/bin/httpd -D FOREGROUND
