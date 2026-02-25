FROM --platform=$BUILDPLATFORM golang:alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /loggregator-release/src
WORKDIR /loggregator-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/rlp ./rlp

FROM gcr.io/distroless/static:latest

COPY --from=builder /usr/local/bin/rlp /usr/local/bin/rlp

ENTRYPOINT [ "/usr/local/bin/rlp" ]
