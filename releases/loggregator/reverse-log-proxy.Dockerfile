FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /loggregator-release/src
WORKDIR /loggregator-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/rlp ./rlp

FROM alpine:latest

COPY --from=builder /usr/local/bin/rlp /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/rlp" ]
