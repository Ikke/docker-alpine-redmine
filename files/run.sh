#!/bin/ash

source /etc/conf.d/postgresql

su -c "pg_ctl start -w -D $PGDATA -l /var/log/postgres.log" postgres

bundle exec ruby bin/rails server webrick -e production -b 0.0.0.0

