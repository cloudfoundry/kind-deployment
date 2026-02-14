FROM --platform=$BUILDPLATFORM golang:1-alpine@sha256:d4c4845f5d60c6a974c6000ce58ae079328d03ab7f721a0734277e69905473e5 AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /networking-release/src
WORKDIR /networking-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/bosh-dns-adapter code.cloudfoundry.org/bosh-dns-adapter

FROM alpine:3.21@sha256:c3f8e73fdb79deaebaa2037150150191b9dcbfba68b4a46d70103204c53f4709

COPY --from=builder /usr/local/bin/bosh-dns-adapter /usr/local/bin/bosh-dns-adapter

ENTRYPOINT [ "/usr/local/bin/bosh-dns-adapter" ]
CMD [ "-c", "/bosh-dns-adapter/bosh-dns-adapter.json" ]
