# Build image
FROM --platform=$BUILDPLATFORM bellsoft/liberica-runtime-container:jdk-25.0.2_12-glibc@sha256:96d9be84078ddfd88a927c5194decf5a2f648f884457d4024afd577930317def AS builder

ARG UAA_RELEASE_VERSION

WORKDIR /uaa
COPY --from=src . .

RUN ./gradlew clean assemble -Pversion=${UAA_RELEASE_VERSION} -x test

# Runtime image
FROM bellsoft/liberica-runtime-container:jre-25.0.2_12-slim-glibc@sha256:d9cee665ee105cf564e00d6adddeef551e449c673ed1806116d25a2d9319f577

ARG UAA_RELEASE_VERSION

COPY --from=files --chmod=755 entrypoint.sh /entrypoint.sh
RUN mkdir /boot

# Install war from build image
COPY --from=builder /uaa/uaa/build/libs/cloudfoundry-identity-uaa-${UAA_RELEASE_VERSION}.war /boot/uaa-boot.war
COPY --from=builder /uaa/k8s/templates/log4j2.properties /log4j2.properties

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
