FROM mhart/alpine-node:6

MAINTAINER Andy Savage <andy@savage.hk>
LABEL description="Customized Storjshare Docker using S6 Overlay"

ARG registry

# This means if the init script fails, e.g. no config, then s6 will quit
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2

ARG S6_OVERLAY_RELEASE="v1.19.1.1"
ARG TMP_BUILD_DIR="/tmp/build"

ENV SJ_CONFIGFILE="/config/config.json"

ENV SJ_DAEMON_LOGLEVEL=3
ENV SJ_DAEMON_RPC_PORT="4000"
ENV SJ_DAEMON_RPC_ADDRESS="0.0.0.0"
ENV SJ_DAEMON_LOG_FILE="/logs/daemon.log"

ARG MAKEFLAGS="-j8"

# Pull in the overlay binaries
ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_RELEASE/s6-overlay-nobin.tar.gz.sig "${TMP_BUILD_DIR}/"

# Pull in the trust keys
COPY keys/trust.gpg "${TMP_BUILD_DIR}/trust.gpg"

RUN \
  addgroup -g 1000 node && \
  adduser -u 1000 -G node -s /bin/sh -D node

# Patch in source for testing sources...
# Update, install necessary packages, fixup permissions, delete junk
RUN \
  apk add --update \
    s6 s6-portable-utils ca-certificates wget tar \
    bash curl g++ git make git python && \
  apk add --virtual verify gnupg && \
  mkdir -p "${TMP_BUILD_DIR}" && \
  chmod 700 "${TMP_BUILD_DIR}" && \
  cd "${TMP_BUILD_DIR}" && \
  wget -q -O "${TMP_BUILD_DIR}/s6-overlay-nobin.tar.gz" https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_RELEASE/s6-overlay-nobin.tar.gz && \
  gpg --no-options --no-default-keyring --homedir "${TMP_BUILD_DIR}" --keyring ./trust.gpg --no-auto-check-trustdb --trust-model always --verify "s6-overlay-nobin.tar.gz.sig" "s6-overlay-nobin.tar.gz" && \
  apk del verify && \
  tar -C / -xzf "s6-overlay-nobin.tar.gz" && \
  npm install \
    --unsafe-perm=true \
    --quiet \
    --production \
    --no-progress \
    --suppess-warnings \
    --registry=${registry:-https://registry.npmjs.org} \
    --global storjshare-daemon && \
  # Fix Daemon Error: https://github.com/indexzero/daemon.node/issues/41
  cd "/usr/lib/node_modules/storjshare-daemon/node_modules" && \
  npm install \
      --quiet \
      --production \
      --no-progress \
      --suppess-warnings \
      'github:zipang/daemon.node#48d0977c26fb3a6a44ae99aae3471b9d5a761085' && \
  npm cache clean \
    --force \
    --suppess-warnings \
    --quiet

RUN rm -r /root/.cache && \
  apk del ca-certificates wget tar curl g++ git make git python && \
  rm -rf /var/cache/apk/* && \
  rm -rf ${TMP_BUILD_DIR}

COPY rootfs/ /

VOLUME ["/config","/logs"]

ENTRYPOINT ["/init"]
