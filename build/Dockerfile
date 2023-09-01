FROM debian:bookworm-slim AS build

ARG GIT_REF=master

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch "$GIT_REF" --depth 1 https://git.zx2c4.com/wireguard-tools \
    && make -C wireguard-tools/src \
    && DESTDIR=build WITH_BASHCOMPLETION=no WITH_WGQUICK=yes WITH_SYSTEMDUNITS=no make -C wireguard-tools/src install


FROM debian:bookworm-slim

COPY --from=build /wireguard-tools/src/build /

RUN apt-get update \
    && apt-get upgrade --yes \
    && apt-get install --yes --no-install-recommends \
        iproute2 \
        iptables \
        openresolv \
    && rm -rf /var/lib/apt/lists/*

# Make wg-quick docker-friendly
RUN sed -i '/sysctl -q net.ipv4.conf.all.src_valid_mark=1/d' \
    "$(which wg-quick)"

COPY docker-entrypoint.sh /usr/local/bin

ENTRYPOINT [ "docker-entrypoint.sh" ]
