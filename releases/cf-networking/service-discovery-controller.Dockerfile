FROM --platform=$BUILDPLATFORM golang:alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /networking-release/src
WORKDIR /networking-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/service-discovery-controller code.cloudfoundry.org/service-discovery-controller

FROM gcr.io/distroless/static:latest

COPY --from=builder /usr/local/bin/service-discovery-controller /usr/local/bin/service-discovery-controller
ENTRYPOINT [ "/usr/local/bin/service-discovery-controller" ]
CMD [ "-c", "/service-discovery-controller/service-discovery-controller.json" ]