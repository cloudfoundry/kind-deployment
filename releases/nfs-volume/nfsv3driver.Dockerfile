FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /nfs-volume-release/src

WORKDIR /nfs-volume-release/src/code.cloudfoundry.org/nfsv3driver
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /usr/local/bin/nfsv3driver code.cloudfoundry.org/nfsv3driver/cmd/nfsv3driver

WORKDIR /nfs-volume-release/src/code.cloudfoundry.org/mapfs
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /usr/local/bin/mapfs code.cloudfoundry.org/mapfs

FROM ubuntu:latest

COPY --from=builder /usr/local/bin/mapfs /usr/local/bin
COPY --from=builder /usr/local/bin/nfsv3driver /usr/local/bin
ADD --chmod=0755 releases/nfs-volume-release/nfsv3driver.sh /nfsv3driver.sh

RUN apt-get update && apt-get install -y nfs-common fuse

ENTRYPOINT [ "/nfsv3driver.sh" ]
