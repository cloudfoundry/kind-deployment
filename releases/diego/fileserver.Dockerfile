FROM --platform=$BUILDPLATFORM python AS builder

ARG TARGETOS TARGETARCH
ARG CF_DEPLOYMENT_VERSION

COPY --from=files . .
RUN pip install -r requirements.txt && python get-compiled-releases.py ${CF_DEPLOYMENT_VERSION}

FROM nginx:latest

COPY --from=builder /tmp/final /fileserver
