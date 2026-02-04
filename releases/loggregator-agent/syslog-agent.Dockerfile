FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /loggregator-agent-release/src
WORKDIR /loggregator-agent-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/syslog-agent ./cmd/syslog-agent

FROM alpine:latest

COPY --from=builder /usr/local/bin/syslog-agent /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/syslog-agent" ]
