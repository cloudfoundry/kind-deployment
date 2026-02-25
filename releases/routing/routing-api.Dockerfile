FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /routing-release/src
WORKDIR /routing-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/routing-api code.cloudfoundry.org/routing-api/cmd/routing-api

FROM gcr.io/distroless/static:latest

COPY --from=builder /usr/local/bin/routing-api /usr/local/bin/routing-api

ENTRYPOINT [ "/usr/local/bin/routing-api" ]
