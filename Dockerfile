#' Define default build variables
ARG ALPINE_VSN='3.17'
ARG UID='9000'
ARG USER='eturnal'
ARG HOME="/opt/$USER"
ARG SOURCE_IMAGE='ghcr.io/sando38/eturnal'
ARG VERSION='1.10.1-127'
ARG WEB_URL='https://eturnal.net'

################################################################################
FROM ${SOURCE_IMAGE}:${VERSION} AS eturnal

FROM docker.io/library/alpine:${ALPINE_VSN} AS runtime

ARG UID
ARG USER
ARG HOME
RUN addgroup "$USER" -g $UID \
    && adduser -s /sbin/nologin -D -u $UID -h "$HOME" -G "$USER" "$USER"

COPY --from=eturnal --chown=$UID:$UID "$HOME" "$HOME"
COPY --from=eturnal /usr/local/bin /usr/local/bin

RUN apk -U upgrade --available --no-cache \
    && apk add --no-cache \
        $(scanelf --needed --nobanner --format '%n#p' --recursive "$HOME" \
        | tr ',' '\n' | sort -u | awk 'system("[ -e "$HOME"" $1 " ]") == 0 { next } \
        { print "so:" $1 }' | sed -e "s|so:libc.so|so:libc.musl-$(uname -m).so.1|") \
        busybox-binsh \
        so:libcap.so.2

RUN apk add --no-cache \
        ca-certificates-bundle \
        openssl \
        s6 \
        socat \
        wget

RUN apk del --repositories-file /dev/null \
        alpine-baselayout \
        alpine-keys \
        apk-tools \
        libc-utils \
    && rm -rf /var/cache/apk /etc/apk \
    && find /lib/apk/db -type f -not -name 'installed' -delete

COPY --chown=$UID:$UID rootfs /

RUN chmod +x /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/*

################################################################################
#' Build together production image
FROM scratch AS prod
ARG VERSION
ARG WEB_URL
ARG USER
ARG HOME
ENV ERL_DIST_PORT='3470' \
    PIPE_DIR="/$HOME/run/pipe/" \
    STUN_SERVICE='stun.conversations.im 3478'

COPY --from=runtime / /

WORKDIR /$HOME
USER $USER
VOLUME ["/$HOME"]
EXPOSE 3478 3478/udp

HEALTHCHECK \
    --interval=1m \
    --timeout=5s \
    --start-period=5s \
    --retries=3 \
    CMD eturnalctl status

LABEL   org.opencontainers.image.title='eturnal' \
        org.opencontainers.image.description='STUN / TURN standalone server' \
        org.opencontainers.image.url="$WEB_URL" \
        org.opencontainers.image.source="https://github.com/sando38/docker-eturnal" \
        org.opencontainers.image.version="$VERSION" \
        org.opencontainers.image.licenses='Apache-2.0'

CMD ["run.sh"]
