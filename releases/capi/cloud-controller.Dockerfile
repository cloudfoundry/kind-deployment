FROM ruby:3.2.9-slim@sha256:f634ac0fe4de30f462f29e5714ecf43c68fc6b5a93d1b4346aa3a919fd21dd05

RUN apt update && apt install -y postgresql-client libpq-dev default-libmysqlclient-dev libyaml-dev build-essential zip git procps && useradd -u 1000 -d /nonexistent -s /sbin/nologin --no-create-home vcap && \
    rm -rf /var/lib/apt/lists/* 

COPY --from=src . /capi-release/src
WORKDIR /capi-release/src/cloud_controller_ng

RUN bundle config set --local without 'development test' && bundle install

COPY <<EOF /usr/bin/setup-db.sh
#!/bin/sh

bundle exec rake db:migrate
bundle exec rake db:seed
EOF

RUN chmod a+x /usr/bin/setup-db.sh && chown -R vcap:vcap /capi-release/src/cloud_controller_ng
USER vcap
