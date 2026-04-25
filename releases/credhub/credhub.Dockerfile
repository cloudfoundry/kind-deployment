# Build image
FROM --platform=$BUILDPLATFORM bellsoft/liberica-openjdk-debian:21 AS builder

WORKDIR /app
COPY --from=src . .

RUN ./gradlew bootJar -x test -x check

# Runtime image
FROM bellsoft/liberica-openjre-debian:21.0.11

WORKDIR /app

COPY --from=files --chmod=0755 /entrypoint.sh /entrypoint.sh
COPY --from=builder /app/applications/credhub-api/build/libs/credhub.jar .

EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
