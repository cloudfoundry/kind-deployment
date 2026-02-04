FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder
ARG TARGETOS TARGETARCH

COPY --from=src . /routing-release/src
WORKDIR /routing-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/gorouter code.cloudfoundry.org/gorouter/cmd/gorouter

FROM alpine:latest

COPY --from=builder /usr/local/bin/gorouter /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/gorouter" ]
CMD [ "-c", "/gorouter/gorouter.yaml" ]
