FROM rockylinux:8
MAINTAINER madebymode

# update dnf
RUN dnf -y update
RUN dnf -y install dnf-utils
RUN dnf clean all

# install epel-release
RUN dnf -y install epel-release

# install remi repo
RUN dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

# reset php
RUN  dnf module reset php -y

# enable php8.0
RUN dnf module install php:remi-7.4 -y

# other binaries
RUN dnf -y install yum-utils mysql rsync wget git expect sudo

# correct php install
RUN  dnf -y install php-{cli,fpm,mysqlnd,zip,devel,gd,mbstring,curl,xml,pear,bcmath,json,intl}

# Update and install latest packages and prerequisites
RUN dnf update -y \
    && dnf install -y --nogpgcheck --setopt=tsflags=nodocs \
        zip \
        unzip \
    && dnf clean all && dnf history new

#composer 1.10
RUN curl -sS https://getcomposer.org/installer | php -- --version=1.10.17 --install-dir=/usr/local/bin --filename=composer
#composer 2
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer2

#PECL
RUN dnf install libmcrypt libmcrypt-devel gcc make -y \
    && wget http://pear.php.net/go-pear.phar \
    && expect -c "spawn php go-pear.phar; expect \"1-12, 'all' or Enter to continue:\"; send \"\r\"; expect \"Would you like to alter php.ini </etc/php.ini>?\"; send \"y\"; send \"\r\"; expect \"Press Enter to continue:\"; send \"\r\"; expect eof;" \
    && rm -rf go-pear.phar \
    && rm -rf /etc/php.d/100-mcrypt.ini \
    && pecl uninstall mcrypt \
    && expect -c "spawn pecl install mcrypt; expect \"autodetect\] :\"; send \"\r\"; expect eof;" \
    && echo "extension=mcrypt.so" > /etc/php.d/100-mcrypt.ini

#wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN sed -e 's/\/run\/php\-fpm\/www.sock/9000/' \
        -e '/allowed_clients/d' \
        -e '/catch_workers_output/s/^;//' \
        -e '/error_log/d' \
        -i /etc/php-fpm.d/www.conf

RUN mkdir /run/php-fpm

CMD ["php-fpm", "-F"]

EXPOSE 9000
