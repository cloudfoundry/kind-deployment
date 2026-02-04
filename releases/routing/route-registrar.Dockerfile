FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /routing-release/src
WORKDIR /routing-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/route-registrar code.cloudfoundry.org/route-registrar

FROM alpine:latest

COPY --from=builder /usr/local/bin/route-registrar /usr/local/bin
COPY --from=files start-route-registrar.sh /usr/local/bin/

RUN apk add --no-cache jq

ENTRYPOINT [ "/usr/local/bin/start-route-registrar.sh" ]
