# 移行先: PHP 8.5 + Apache 2.4 (mod_php) + SQLite 3（pdo_sqlite は公式イメージに同梱）
FROM php:8.5-apache
COPY php.ini /usr/local/etc/php/conf.d/zz-app.ini
# 旧環境とパスを揃える（/var/www/app, /var/www/data, /var/www/db）
ENV APACHE_DOCUMENT_ROOT=/var/www/app
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}/!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
 && mkdir -p /var/www/app /var/www/data && chmod 777 /var/www/data
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh
CMD ["/usr/local/bin/start.sh"]
