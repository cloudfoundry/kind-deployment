FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /loggregator-release/src
WORKDIR /loggregator-release/src

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/doppler ./router

FROM gcr.io/distroless/static:latest

COPY --from=builder /usr/local/bin/doppler /usr/local/bin/doppler

ENTRYPOINT [ "/usr/local/bin/doppler" ]
