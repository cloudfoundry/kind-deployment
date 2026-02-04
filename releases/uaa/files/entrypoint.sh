#!/bin/sh

SECRETS_DIR=${SECRETS_DIR:-/secrets}
LOGGING_CONFIG=${LOGGING_CONFIG:-/log4j2.properties}
SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE:-postgresql}
CLOUDFOUNDRY_CONFIG_PATH=${CLOUDFOUNDRY_CONFIG_PATH:-/cf_config}
APPLICATION_YAML=${APPLICATION_YAML:-/application.yml}
BOOT_RUN_LOCATION=${BOOT_RUN_LOCATION:-/boot}
UAA_CONFIG_FILE=${UAA_CONFIG_FILE:-/uaa.yml}

JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"
JAVA_OPTS="$JAVA_OPTS -Dnetworkaddress.cache.ttl=0"
JAVA_OPTS="$JAVA_OPTS -Dlog4j.configurationFile=$LOGGING_CONFIG -Dlogging.config=$LOGGING_CONFIG"
JAVA_OPTS="$JAVA_OPTS -Dlog4j2.formatMsgNoLookups=true"
JAVA_OPTS="$JAVA_OPTS -Djava.io.tmpdir=/tmp"
JAVA_OPTS="$JAVA_OPTS -DSECRETS_DIR=$SECRETS_DIR"
JAVA_OPTS="$JAVA_OPTS -DCLOUDFOUNDRY_CONFIG_PATH=$CLOUDFOUNDRY_CONFIG_PATH"
JAVA_OPTS="$JAVA_OPTS -Dmetrics.perRequestMetrics=true"
JAVA_OPTS="$JAVA_OPTS -Dserver.servlet.context-path=/"
JAVA_OPTS="$JAVA_OPTS -Dstatsd.enabled=true"
JAVA_OPTS="$JAVA_OPTS -Dservlet.session-store=database"
JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=$SPRING_PROFILES_ACTIVE"
JAVA_OPTS="$JAVA_OPTS -Dspring.config.location=$APPLICATION_YAML"
JAVA_OPTS="$JAVA_OPTS -DLOGIN_CONFIG_URL=file://$UAA_CONFIG_FILE"

trap 'kill -TERM "$java_pid"' SIGTERM SIGINT

cd $BOOT_RUN_LOCATION
java $JAVA_OPTS -jar /boot/uaa-boot.war &
java_pid=$!

wait "$java_pid"
