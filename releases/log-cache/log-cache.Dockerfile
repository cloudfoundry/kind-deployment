FROM --platform=$BUILDPLATFORM golang:1-alpine@sha256:d4c4845f5d60c6a974c6000ce58ae079328d03ab7f721a0734277e69905473e5 AS builder

ARG component TARGETOS TARGETARCH LOG_CACHE_RELEASE_VERSION

COPY --from=src . /log-cache-release/src
WORKDIR /log-cache-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags "-X main.buildVersion=${LOG_CACHE_RELEASE_VERSION}" -o /usr/local/bin/cmd code.cloudfoundry.org/log-cache/cmd/${component}

FROM alpine:3.21@sha256:c3f8e73fdb79deaebaa2037150150191b9dcbfba68b4a46d70103204c53f4709

COPY --from=builder /usr/local/bin/cmd /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/cmd" ]
