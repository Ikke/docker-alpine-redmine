FROM alpine

RUN sed -Ei 's/v[0-9]\.[0-9]+/edge/' /etc/apk/repositories \
    && apk upgrade --update-cache --available \
    && apk add redmine postgresql ruby-pg

ADD files/database.yml /etc/redmine/database.yml

ADD files/run.sh /usr/share/webapps/redmine/run.sh
RUN chmod 755 /usr/share/webapps/redmine/run.sh

RUN source /etc/conf.d/postgresql \
    && install -Dd -o postgres -g postgres -m 0700 $PGDATA \
    && su -c "/usr/bin/initdb --pgdata ${PGDATA}" postgres \
    && install -o postgres -g postgres -m 644 /dev/null /var/log/postgres.log \
    && su -c "pg_ctl start -w -D $PGDATA -l /var/log/postgres.log" postgres \
    && until [ -S /tmp/.s.PGSQL.5432 ]; do sleep 1; done \
    && createuser -U postgres redmine \
    && createdb -U postgres -O redmine redmine \
    && su -c "pg_ctl stop -w -D $PGDATA" postgres

WORKDIR /usr/share/webapps/redmine
ENV RAILS_ENV=production
ENV REDMINE_LANG=en

RUN bundle exec rake generate_secret_token \
    && source /etc/conf.d/postgresql \
    && su -c "pg_ctl start -D $PGDATA -l /var/log/postgres.log" postgres \
    && until [ -S /tmp/.s.PGSQL.5432 ]; do sleep 1; done \
    && bundle exec rake db:migrate \
    && bundle exec rake redmine:load_default_data \
    && su -c "pg_ctl stop -w -D $PGDATA" postgres

EXPOSE 3000
ENTRYPOINT ["/usr/share/webapps/redmine/run.sh"]
