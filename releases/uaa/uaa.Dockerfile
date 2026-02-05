# Build image
FROM --platform=$BUILDPLATFORM bellsoft/liberica-runtime-container:jdk-25.0.1_11-glibc AS builder

ARG UAA_RELEASE_VERSION

WORKDIR /uaa
COPY --from=src . .

RUN ./gradlew clean assemble -Pversion=${UAA_RELEASE_VERSION} -x test

# Runtime image
FROM bellsoft/liberica-runtime-container:jre-25.0.1_11-slim-glibc

ARG UAA_RELEASE_VERSION

COPY --from=files --chmod=755 entrypoint.sh /entrypoint.sh
RUN mkdir /boot

# Install war from build image
COPY --from=builder /uaa/uaa/build/libs/cloudfoundry-identity-uaa-${UAA_RELEASE_VERSION}.war /boot/uaa-boot.war
COPY --from=builder /uaa/k8s/templates/log4j2.properties /log4j2.properties

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
