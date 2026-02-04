FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /diego-release/src
WORKDIR /diego-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/ssh-proxy code.cloudfoundry.org/diego-ssh/cmd/ssh-proxy

FROM alpine:latest

COPY --from=builder /usr/local/bin/ssh-proxy /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/ssh-proxy" ]
CMD [ "-config", "/ssh-proxy/ssh-proxy.json" ]
