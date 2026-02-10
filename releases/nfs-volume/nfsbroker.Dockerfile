FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /nfs-volume-release/src
WORKDIR /nfs-volume-release/src/code.cloudfoundry.org/nfsbroker

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/nfsbroker code.cloudfoundry.org/nfsbroker

FROM alpine:latest

COPY --from=builder /usr/local/bin/nfsbroker /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/nfsbroker" ]
