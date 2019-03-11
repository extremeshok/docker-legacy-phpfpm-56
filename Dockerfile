FROM ubuntu:xenial
MAINTAINER Adrian Kriel <admin@extremeshok.com>

# php-fpm 5.6 with geoip, redis, memcached, mysql, sqlite, composer, imagick

ENV DEBIAN_FRONTEND=noninteractive

ENV PHP_VERSION=5.6 \
	OS_LOCALE="en_US.UTF-8"

ENV LANG=${OS_LOCALE} \
  LANGUAGE=${OS_LOCALE} \
  LC_ALL=${OS_LOCALE}

WORKDIR /tmp/provisioning/

# Install
RUN apt-get update \
	&& SOFTWARE_BUILD_DEPS=" \
	apt-transport-https \
	build-essential \
	lsb-release \
	make \
	python-software-properties \
	software-properties-common \
	unzip " \
	&& apt-get install --no-install-recommends -y $SOFTWARE_BUILD_DEPS sudo curl iputils-ping locales \
	&& LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php \
	&& rm -rf /var/lib/apt/lists/*

RUN locale-gen ${OS_LOCALE}

# install PHP and extensionsADD
RUN apt-get update \
	&& PHP_BUILD_DEPS=" \
		$PHP_EXTRA_BUILD_DEPS \
		php5.6 \
		php5.6-cli \
		php5.6-curl \
		php5.6-dev \
		php5.6-fpm \
		php5.6-gd \
		php5.6-geoip \
		php5.6-imagick \
		php5.6-imap \
		php5.6-json \
		php5.6-mbstring \
		php5.6-mcrypt \
		php5.6-memcached \
		php5.6-mysql \
		php5.6-ps \
		php5.6-pspell \
		php5.6-recode \
		php5.6-redis \
		php5.6-sqlite \
		php5.6-tidy \
		php5.6-xml " \
	&& set -x \
	&& apt-get install --no-install-recommends -y $PHP_BUILD_DEPS \
  && rm -rf /var/lib/apt/lists/*

# fix permissions & CLEANUP
RUN mkdir -p /var/www/ \
  && chown -R www-data:www-data /var/www \
	&& rm -rf /var/lib/apt/lists/*

# Forward request and error logs to docker log collector
#RUN	 mkdir -p /var/log/php \
#	&& ln -sf /dev/stderr /var/log/php/error.log

RUN	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# IONCUBE LOADER
RUN mkdir -p /tmp/IONCUBE && cd /tmp/IONCUBE \
	&& curl -sS https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube_loaders_lin_x86-64.tar.gz \
	&& tar -xzf ioncube_loaders_lin_x86-64.tar.gz \
	&& cp -f ioncube/ioncube_loader_lin_5.6.so /usr/lib/php/20131226/ioncube_loader_lin.so \
	&& echo "zend_extension=ioncube_loader_lin.so" > /etc/php/5.6/cli/conf.d/0-ioncube.ini \
	&& echo "zend_extension=ioncube_loader_lin.so" > /etc/php/5.6/fpm/conf.d/0-ioncube.ini \
	&& rm -rf /tmp/IONCUBE

# deprecated, we now include the last available library
# # GEOIP databases
# RUN mkdir -p /usr/share/GeoIP && cd /usr/share/GeoIP \
# 	&& curl -sS http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz -o GeoIP.dat.gz \
# 	&& gunzip GeoIP.dat.gz \
# 	&& curl -sS http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz -o GeoLiteCity.dat.gz \
# 	&& gunzip GeoLiteCity.dat.gz \
# 	&& rm -f /usr/share/GeoIP/*.dat.gz

# Supervisor Demon manager and cron
RUN apt-get update \
	&& apt-get install -y --no-install-recommends cron supervisor

RUN apt-get update \
	&& apt-get purge -y --auto-remove $SOFTWARE_BUILD_DEPS \
	&& rm -rf /tmp/provisioning \
	&& rm -rf /var/lib/apt/lists/*


WORKDIR /var/www/

EXPOSE 9000

# add local files
COPY ./rootfs/ /

RUN chmod 777 /usr/local/bin/supervisor-watcher
RUN chmod 744 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
