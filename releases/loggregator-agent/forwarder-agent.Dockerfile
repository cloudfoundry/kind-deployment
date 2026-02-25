FROM --platform=$BUILDPLATFORM golang:alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /loggregator-agent-release/src
WORKDIR /loggregator-agent-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/forwarder-agent ./cmd/forwarder-agent

FROM ubuntu:latest


ENV DOWNSTREAM_INGRESS_PORT_GLOB="/ingress-globs/*.yml"
COPY --from=builder /usr/local/bin/forwarder-agent /usr/local/bin/forwarder-agent

RUN mkdir /ingress-globs && echo "---\ningress: 3460" > /ingress-globs/syslog.yml && echo "---\ningress: 3459" > /ingress-globs/loggregator.yml

ENTRYPOINT [ "/usr/local/bin/forwarder-agent" ]
