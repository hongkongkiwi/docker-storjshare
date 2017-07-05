FROM hongkongkiwi/node-alpine-s6-overlay

MAINTAINER Andy Savage <andy@savage.hk>
LABEL description="Customized Storjshare Docker"

ARG registry

# This means if the init script fails, e.g. no config, then s6 will quit
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2

RUN \
  apk add -q --no-cache \
    git python ca-certificates wget tar bash curl g++ git make && \
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

COPY rootfs/ /

ENV SJ_CONFIGFILE="/config/config.json"

ENV SJ_DAEMON_LOGLEVEL=3
ENV SJ_DAEMON_RPC_PORT="45015"
ENV SJ_DAEMON_RPC_ADDRESS="0.0.0.0"
ENV SJ_DAEMON_LOG_FILE="/logs/daemon.log"

VOLUME ["/config","/logs"]

ENTRYPOINT ["/init"]
