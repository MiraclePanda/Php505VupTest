# 移行先: PHP 8.5 + Apache 2.4 (mod_php)
FROM php:8.5-apache
RUN docker-php-ext-install mysqli pdo_mysql
COPY php.ini /usr/local/etc/php/conf.d/zz-app.ini
