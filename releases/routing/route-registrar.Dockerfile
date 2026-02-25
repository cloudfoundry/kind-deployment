FROM --platform=$BUILDPLATFORM golang:alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /routing-release/src
WORKDIR /routing-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/route-registrar code.cloudfoundry.org/route-registrar

FROM ubuntu:latest

COPY --from=builder /usr/local/bin/route-registrar /usr/local/bin
COPY --from=files start-route-registrar.sh /usr/local/bin/

RUN apt update && apt install -y jq && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/usr/local/bin/start-route-registrar.sh" ]
