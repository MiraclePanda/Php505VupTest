# PHP 5.0.5 + Apache 2.0 (mod_php) + SQLite 2（PHP 同梱）の当時相当の実行環境
#   2005年当時の典型構成を再現するため、Debian 4.0 (etch) 上で
#   Apache 2.0.65 と PHP 5.0.5 をソースからビルドする。
FROM debian/eol:etch

RUN apt-get update \
 && apt-get install -y --force-yes \
      build-essential libxml2-dev zlib1g-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# ソースは Docker デーモン側で取得する（etch の wget は現在の TLS に対応しないため）
ARG APACHE_URL=https://archive.apache.org/dist/httpd/httpd-2.0.65.tar.gz
ARG PHP_URL=https://museum.php.net/php5/php-5.0.5.tar.gz
ADD ${APACHE_URL} /usr/src/httpd.tar.gz
ADD ${PHP_URL} /usr/src/php.tar.gz

RUN cd /usr/src && mkdir httpd && tar xzf httpd.tar.gz -C httpd --strip-components=1 \
 && cd httpd \
 && ./configure --prefix=/usr/local/apache2 --enable-so --with-mpm=prefork \
 && make && make install \
 && cd /usr/src && rm -rf httpd httpd.tar.gz

RUN cd /usr/src && mkdir php && tar xzf php.tar.gz -C php --strip-components=1 \
 && cd php \
 && ./configure \
      --prefix=/usr/local/php5 \
      --with-apxs2=/usr/local/apache2/bin/apxs \
      --with-config-file-path=/usr/local/php5/lib \
      --enable-mbstring \
      --with-zlib \
      --without-pear \
 && make && make install \
 && cd /usr/src && rm -rf php php.tar.gz

COPY php.ini /usr/local/php5/lib/php.ini
COPY httpd-app.conf /usr/local/apache2/conf/httpd-app.conf
RUN sed -i \
      -e 's/^Group #-1/Group nogroup/' \
      -e 's#^ErrorLog .*#ErrorLog /proc/self/fd/2#' \
      -e 's#^CustomLog .*#CustomLog /proc/self/fd/1 common#' \
      /usr/local/apache2/conf/httpd.conf \
 && echo 'Include conf/httpd-app.conf' >> /usr/local/apache2/conf/httpd.conf \
 && mkdir -p /var/www/app /var/www/data && chmod 777 /var/www/data
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ENV PATH=/usr/local/php5/bin:/usr/local/apache2/bin:$PATH
EXPOSE 80
CMD ["/usr/local/bin/start.sh"]
