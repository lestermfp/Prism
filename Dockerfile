FROM buildpack-deps:bullseye

ENV NGINX_VERSION nginx-1.18.0
ENV NGINX_RTMP_MODULE_VERSION 1.2.1

RUN apt-get update && \
    apt-get install -y ca-certificates openssl libssl-dev stunnel4 gettext && \
    rm -rf /var/lib/apt/lists/*

COPY --from=mwader/static-ffmpeg:7.1.1 /ffmpeg /usr/bin/
COPY --from=mwader/static-ffmpeg:7.1.1 /ffprobe /usr/bin/

RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

RUN mkdir -p /tmp/build/nginx-rtmp-module && \
    cd /tmp/build/nginx-rtmp-module && \
    wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar -zxf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    cd nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}


# nginx goes to /usr/local/nginx
RUN cd /tmp/build/nginx/${NGINX_VERSION} && \
    ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --with-ipv6 \
        --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
    make -j $(getconf _NPROCESSORS_ONLN) CFLAGS="-Wno-error" && \
    make install && \
    mkdir /var/lock/nginx && \
    rm -rf /tmp/build

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Config Stunnel
RUN mkdir -p  /etc/stunnel/conf.d
COPY stunnel/stunnel.conf /etc/stunnel/stunnel.conf
COPY stunnel/stunnel4 /etc/default/stunnel4

#Facebook Stunnel Port 19350
COPY stunnel/facebook.conf /etc/stunnel/conf.d/facebook.conf

#Instagram Stunnel Port 19351
COPY stunnel/instagram.conf /etc/stunnel/conf.d/instagram.conf

#Cloudflare Stunnel Port 19352
COPY stunnel/cloudflare.conf /etc/stunnel/conf.d/cloudflare.conf

#Kick Stunnel Port 19353
COPY stunnel/kick.conf /etc/stunnel/conf.d/kick.conf

#Telegram Stunnel Port 19354
COPY stunnel/telegram.conf /etc/stunnel/conf.d/telegram.conf

#Youtube
ENV YOUTUBE_URL rtmp://a.rtmp.youtube.com/live2/
ENV YOUTUBE_KEY ""

#Facebook
ENV FACEBOOK_URL rtmp://127.0.0.1:19350/rtmp/
ENV FACEBOOK_KEY ""

#Instagram
ENV INSTAGRAM_URL rtmp://127.0.0.1:19351/rtmp/
ENV INSTAGRAM_KEY ""

#Cloudflare
ENV CLOUDFLARE_URL rtmp://127.0.0.1:19352/live/
ENV CLOUDFLARE_KEY ""

#Twitch
ENV TWITCH_URL ""
ENV TWITCH_KEY ""

#Rtmp1
ENV RTMP1_URL ""
ENV RTMP1_KEY ""

#Rtmp2
ENV RTMP2_URL ""
ENV RTMP2_KEY ""

#Rtmp3
ENV RTMP3_URL ""
ENV RTMP3_KEY ""

#Trovo
ENV TROVO_URL rtmp://livepush.trovo.live/live/
ENV TROVO_KEY ""

#Kick
ENV KICK_URL rtmp://127.0.0.1:19353/kick/
ENV KICK_KEY ""

#Telegram
ENV TELEGRAM_URL rtmp://127.0.0.1:19354/s/
ENV TELEGRAM_KEY ""

ENV DEBUG ""

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

EXPOSE 1935

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
