FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /networking-release/src
WORKDIR /networking-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/policy-server code.cloudfoundry.org/policy-server/cmd/policy-server
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/policy-server-internal code.cloudfoundry.org/policy-server/cmd/policy-server-internal
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/policy-server-asg-syncer code.cloudfoundry.org/policy-server/cmd/policy-server-asg-syncer

FROM alpine:latest

COPY --from=builder /usr/local/bin/* /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/policy-server" ]
CMD [ "-config-file", "/policy-server/policy-server.json" ]
