FROM alpine:latest AS builder

RUN apk add --no-cache curl

COPY --from=storage-cli . /storage-cli
WORKDIR /storage-cli

RUN STORAGE_CLI_RELEASE_VERSION=$(sed -n 's/.*storage_cli_version="\([^"]*\)".*/\1/p' packaging) && \
    curl https://github.com/cloudfoundry/storage-cli/releases/download/v${STORAGE_CLI_RELEASE_VERSION}/storage-cli-${STORAGE_CLI_RELEASE_VERSION}-linux-amd64 -L -o /usr/local/bin/storage-cli && \
    chmod +x /usr/local/bin/storage-cli

FROM ruby:4.0.3-slim

RUN apt update && apt install -y postgresql-client libpq-dev default-libmysqlclient-dev libyaml-dev build-essential zip git procps && useradd -u 1000 -d /nonexistent -s /sbin/nologin --no-create-home vcap && \
    rm -rf /var/lib/apt/lists/* 

COPY --from=src . /capi-release/src
COPY --from=builder /usr/local/bin/storage-cli /usr/local/bin/storage-cli

WORKDIR /capi-release/src/cloud_controller_ng

RUN bundle config set --local without 'development test' && bundle install

COPY <<EOF /usr/bin/setup-db.sh
#!/bin/sh

bundle exec rake db:migrate
bundle exec rake db:seed
EOF

RUN chmod a+x /usr/bin/setup-db.sh && chown -R vcap:vcap /capi-release/src/cloud_controller_ng
USER vcap
