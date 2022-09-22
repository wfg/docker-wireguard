FROM alpine:3.16

RUN apk add --no-cache \
    wireguard-tools

# Make wg-quick docker-friendly
RUN sed -i '/sysctl -q net.ipv4.conf.all.src_valid_mark=1/d' \
    "$(which wg-quick)"

COPY entry.sh /usr/local/bin

ENTRYPOINT [ "entry.sh" ]

ARG BUILD_DATE
ARG IMAGE_VERSION
LABEL build-date=$BUILD_DATE
LABEL image-version=$IMAGE_VERSION
