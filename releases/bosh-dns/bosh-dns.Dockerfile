FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /bosh-dns-release/src
WORKDIR /bosh-dns-release/src/bosh-dns

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/bosh-dns ./dns

FROM alpine:latest

COPY --from=builder /usr/local/bin/bosh-dns /usr/local/bin/bosh-dns

ENTRYPOINT [ "/usr/local/bin/bosh-dns" ]
CMD [ "-config", "/bosh-dns/bosh-dns.json" ]
