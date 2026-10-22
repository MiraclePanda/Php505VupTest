# 移行先: PHP 8.5 + Apache 2.4 (mod_php) + unixODBC + SQLite 3 ODBC ドライバ
#   odbc（odbc_* 関数）と pdo_odbc の両方を入れ、移行方式をどちらにも選べるようにしている。
FROM php:8.5-apache
RUN apt-get update \
 && apt-get install -y --no-install-recommends unixodbc unixodbc-dev libsqliteodbc \
 && rm -rf /var/lib/apt/lists/*
# odbc は phpize でビルドすると configure が全ドライバを有効扱いにするため、該当行を sed で無効化する
RUN docker-php-source extract \
 && cd /usr/src/php/ext/odbc \
 && phpize \
 && sed -ri 's@^ *test +"\$PHP_.*" *= *"no" *&& *PHP_.*=yes *$@#&@g' configure \
 && ./configure --with-unixODBC \
 && make -j"$(nproc)" && make install \
 && docker-php-ext-enable odbc \
 && docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC \
 && docker-php-ext-install pdo_odbc \
 && docker-php-source delete
# ODBC: SQLite 3 ドライバを登録し、データソース "shop" を定義する
RUN DRV=$(find /usr/lib -name 'libsqlite3odbc*.so' | head -1) \
 && test -n "$DRV" \
 && printf '[SQLite3]\nDescription=SQLite 3 ODBC Driver\nDriver=%s\n' "$DRV" > /etc/odbcinst.ini \
 && printf '[shop]\nDriver=SQLite3\nDatabase=/var/www/data/shop.db\n' > /etc/odbc.ini
COPY php.ini /usr/local/etc/php/conf.d/zz-app.ini
# 旧環境とパスを揃える（/var/www/app, /var/www/data, /var/www/db）
ENV APACHE_DOCUMENT_ROOT=/var/www/app
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}/!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
 && mkdir -p /var/www/app /var/www/data && chmod 777 /var/www/data
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh
CMD ["/usr/local/bin/start.sh"]
