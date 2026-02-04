FROM alpine

WORKDIR /src

COPY --from=files upload_module_put_support.patch /src/upload_module_put_support.patch

RUN apk add --no-cache build-base curl tar openssl-dev pcre2-dev patch \
  && addgroup -g 1000 -S vcap \
  && adduser -h /nonexistent -S -D -H -u 1000 -G vcap vcap \
  && mkdir /nginx \
  && curl -Lo nginx-upload-module.tgz https://github.com/vkholodkov/nginx-upload-module/archive/2.3.0.tar.gz \
  && curl -Lo nginx.tgz               https://nginx.org/download/nginx-1.28.0.tar.gz \
  && mkdir nginx-upload-module nginx \
  && tar -xf nginx-upload-module.tgz -C nginx-upload-module --strip-components=1 \
  && tar -xf nginx.tgz               -C nginx               --strip-components=1 \
  && rm *.tgz \
  && cd nginx-upload-module && patch < /src/upload_module_put_support.patch && cd - \
  && cd nginx \
  && sed -i 's@"nginx/"@"-/"@g' src/core/nginx.h \
  && sed -i 's@r->headers_out.server == NULL@0@g' src/http/ngx_http_header_filter_module.c \
  && sed -i 's@r->headers_out.server == NULL@0@g' src/http/v2/ngx_http_v2_filter_module.c \
  && sed -i 's@<hr><center>nginx</center>@@g' src/http/ngx_http_special_response.c \
  && ./configure --prefix=/nginx --conf-path=/etc/nginx/nginx.conf --with-pcre --add-module=../nginx-upload-module --with-http_stub_status_module --with-http_ssl_module \
  && make install \
  && apk del --no-cache build-base tar \
  && chown -R vcap:vcap /nginx

USER vcap
ENTRYPOINT [ "/nginx/sbin/nginx" ]
CMD [ "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf" ]
