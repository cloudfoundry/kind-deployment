FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /loggregator-release/src
WORKDIR /loggregator-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/rlp-gateway ./rlp-gateway

FROM gcr.io/distroless/static:latest

COPY --from=builder /usr/local/bin/rlp-gateway /usr/local/bin/rlp-gateway

ENTRYPOINT [ "/usr/local/bin/rlp-gateway" ]
