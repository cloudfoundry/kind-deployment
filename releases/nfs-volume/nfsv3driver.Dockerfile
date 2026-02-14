FROM --platform=$BUILDPLATFORM golang:1-alpine@sha256:d4c4845f5d60c6a974c6000ce58ae079328d03ab7f721a0734277e69905473e5 AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /nfs-volume-release/src

WORKDIR /nfs-volume-release/src/code.cloudfoundry.org/nfsv3driver
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /usr/local/bin/nfsv3driver code.cloudfoundry.org/nfsv3driver/cmd/nfsv3driver

WORKDIR /nfs-volume-release/src/code.cloudfoundry.org/mapfs
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /usr/local/bin/mapfs code.cloudfoundry.org/mapfs

FROM ubuntu:24.04@sha256:cd1dba651b3080c3686ecf4e3c4220f026b521fb76978881737d24f200828b2b

COPY --from=builder /usr/local/bin/mapfs /usr/local/bin
COPY --from=builder /usr/local/bin/nfsv3driver /usr/local/bin
ADD --chmod=0755 releases/nfs-volume/nfsv3driver.sh /nfsv3driver.sh

RUN apt-get update && apt-get install -y nfs-common fuse

ENTRYPOINT [ "/nfsv3driver.sh" ]
