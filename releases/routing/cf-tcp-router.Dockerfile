FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /routing-release/src
WORKDIR /routing-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/cf-tcp-router code.cloudfoundry.org/cf-tcp-router/cmd/cf-tcp-router

FROM alpine:latest

COPY --from=builder /usr/local/bin/cf-tcp-router /usr/local/bin
ADD --chmod=0755 releases/routing/files/haproxy_reloader.sh /usr/local/bin/haproxy_reloader.sh

ENTRYPOINT [ "/usr/local/bin/cf-tcp-router" ]
