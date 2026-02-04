FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /loggregator-agent-release/src
WORKDIR /loggregator-agent-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/syslog-binding-cache ./cmd/syslog-binding-cache

FROM alpine:latest

COPY --from=builder /usr/local/bin/syslog-binding-cache /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/syslog-binding-cache" ]
