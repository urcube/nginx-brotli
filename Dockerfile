ARG NGINX_VERSION=alpine
FROM nginx:${NGINX_VERSION} AS builder

# 1. Install build dependencies
RUN apk add --no-cache --virtual .build-deps \
    gcc libc-dev make openssl-dev pcre2-dev zlib-dev \
    linux-headers libtool automake autoconf git g++ cmake

RUN mkdir -p /usr/src

# 2. Extract configuration and build
# We use -fPIC and strip specific flags to ensure the binary module 'snaps' into the Nginx binary
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*configure arguments: //p') \
    && VERSION=$(nginx -v 2>&1 | sed -n -e 's/^.*nginx\///p') \
    && CONFARGS=$(echo $CONFARGS | sed "s/-fstack-clash-protection//g" | sed "s/-fstack-protector-strong//g") \
    && wget "http://nginx.org/download/nginx-$VERSION.tar.gz" -O nginx.tar.gz \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && git clone --recursive https://github.com/google/ngx_brotli.git /usr/src/ngx_brotli \
    && cd /usr/src/ngx_brotli/deps/brotli \
    && mkdir out && cd out \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-fPIC" .. \
    && cmake --build . --config Release --target brotlienc \
    && cd ../../../.. \
    && cd /usr/src/nginx-$VERSION \
    && eval ./configure $CONFARGS --add-dynamic-module=/usr/src/ngx_brotli \
    && make modules

# Stage 2: Final Image
FROM nginx:${NGINX_VERSION} AS final

# Copy modules from builder
COPY --from=builder /usr/src/nginx-*/objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/
COPY --from=builder /usr/src/nginx-*/objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/

# 3. Load modules at the very top of nginx.conf
RUN sed -i '1i load_module /usr/lib/nginx/modules/ngx_http_brotli_filter_module.so;' /etc/nginx/nginx.conf \
    && sed -i '1i load_module /usr/lib/nginx/modules/ngx_http_brotli_static_module.so;' /etc/nginx/nginx.conf

# --- Stage 3: Tester ---
FROM final AS tester
RUN apk add --no-cache curl