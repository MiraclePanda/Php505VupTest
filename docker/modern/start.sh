#!/bin/sh
# DB がなければ初期化してから Apache を起動する
[ -f /var/www/data/shop.db ] || php /var/www/db/init_modern.php
exec docker-php-entrypoint apache2-foreground
