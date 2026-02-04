FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG component TARGETOS TARGETARCH LOG_CACHE_RELEASE_VERSION

COPY --from=src . /log-cache-release/src
WORKDIR /log-cache-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags "-X main.buildVersion=${LOG_CACHE_RELEASE_VERSION}" -o /usr/local/bin/cmd code.cloudfoundry.org/log-cache/cmd/${component}

FROM alpine:latest

COPY --from=builder /usr/local/bin/cmd /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/cmd" ]
