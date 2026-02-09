ARG NGINX_VERSION=1.28.0

FROM debian:bookworm AS builder
ARG NGINX_VERSION

WORKDIR /src

RUN apt update && apt install curl git libpcre2-dev libssl-dev zlib1g-dev build-essential -y && \
  mkdir nginx-upload-module nginx && \
  curl -L https://github.com/vkholodkov/nginx-upload-module/archive/2.3.0.tar.gz | tar xz --strip-components=1 -C nginx-upload-module && \
  curl -L https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar xz --strip-components=1 -C nginx

COPY --from=src nginx /src/nginx-upload-module/patches

RUN cd /src/nginx-upload-module && \
  patch < /src/nginx-upload-module/patches/upload_module_new_nginx_support.patch && \
  patch < /src/nginx-upload-module/patches/upload_module_put_support.patch

RUN cd /src/nginx && ./configure --add-dynamic-module=/src/nginx-upload-module --with-compat && \
  make modules

FROM nginx:${NGINX_VERSION}

COPY --from=builder /src/nginx/objs/ngx_http_upload_module.so /etc/nginx/modules/ngx_http_upload_module.so

RUN addgroup --gid 1000 vcap && adduser --home /nonexistent --no-create-home --shell /bin/false --system --uid 1000 --gid 1000 vcap
