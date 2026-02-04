FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /networking-release/src
WORKDIR /networking-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/bosh-dns-adapter code.cloudfoundry.org/bosh-dns-adapter

FROM alpine:latest

COPY --from=builder /usr/local/bin/bosh-dns-adapter /usr/local/bin/bosh-dns-adapter

ENTRYPOINT [ "/usr/local/bin/bosh-dns-adapter" ]
CMD [ "-c", "/bosh-dns-adapter/bosh-dns-adapter.json" ]
