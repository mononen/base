ARG UPSTREAM_IMAGE=alpine
ARG UPSTREAM_VERSION=3.18

FROM --platform=linux/amd64 alpine AS builder 

ARG UNRAR_VER=6.2.4

RUN apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    build-base \
    cmake \
    cppunit-dev \
    curl-dev \
    libtool \
    linux-headers \
    zlib-dev \
# Install unrar from source
&& cd /tmp \
&& wget https://www.rarlab.com/rar/unrarsrc-${UNRAR_VER}.tar.gz -O /tmp/unrar.tar.gz \
&& tar -xzf /tmp/unrar.tar.gz \
&& cd unrar \
&& make -f makefile \
&& install -Dm 755 unrar /usr/bin/unrar


FROM ${UPSTREAM_IMAGE}:${UPSTREAM_VERSION}

ENV APP_DIR="/app" CONFIG_DIR="/config" PUID="568" PGID="568" UMASK="002" TZ="Etc/UTC" ARGS=""
ENV XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

ENTRYPOINT ["/init"]

# install packages
RUN apk add --no-cache tzdata shadow bash curl wget jq grep sed coreutils findutils python3 unzip p7zip ca-certificates

COPY --from=builder /usr/bin/unrar /usr/bin/

# make folders
RUN mkdir "${APP_DIR}" && \
    mkdir "${CONFIG_DIR}" && \
# create user
    useradd -u 568 -U -d "${CONFIG_DIR}" -s /bin/false hotio && \
    usermod -G users hotio

ARG BUILD_ARCHITECTURE
ENV BUILD_ARCHITECTURE=$BUILD_ARCHITECTURE
