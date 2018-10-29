#!/bin/bash

log_f() {
  if [[ ${2} == "no_nl" ]]; then
    echo -n "$(date) - ${1}"
  elif [[ ${2} == "no_date" ]]; then
    echo "${1}"
  elif [[ ${2} != "redis_only" ]]; then
    echo "$(date) - ${1}"
  fi
  #redis-cli -h redis LPUSH ACME_LOG "{\"time\":\"$(date +%s)\",\"message\":\"$(printf '%s' "${1}" | \
  #tr '%&;$"_[]{}-\r\n' ' ')\"}" > /dev/null
  #redis-cli -h redis LTRIM ACME_LOG 0 ${LOG_LINES} > /dev/null
  echo "{\"time\":\"$(date +%s)\",\"message\":\"$(printf '%s' "${1}")\"}"
}

#bugfix for old apache2 not creating the dirs
mkdir -p /var/run/apache2
mkdir -p /var/cache/apache2


if [[ "${ENABLE_PHP_REDIS_SESSIONS}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then

  log_f "Enabled PHP Redis Session Storage" no_nl

  cat << EOF > /etc/php5/apache2/conf.d/docker-php-redis-sessions.ini
session.save_handler = redis
session.save_path = redis:6379
EOF

  log_f "Waiting for Docker Redis..." no_nl
  until ping redis -c1 > /dev/null; do
    sleep 1
  done
  log_f "Found Docker Redis" no_date
fi

source /etc/apache2/envvars

chown -R www-data:www-data /var/www;

#tail -F /var/log/apache2/* &
#exec /usr/sbin/php5-fpm -F
