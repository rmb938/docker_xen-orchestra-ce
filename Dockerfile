FROM node:12-alpine as build

WORKDIR /home/node

RUN apk add --no-cache git python2 g++ make bash

# TODO: figure out how to get a specific version
RUN git clone -b master https://github.com/vatesfr/xen-orchestra

RUN cd /home/node/xen-orchestra && \
    yarn config set network-timeout 300000
RUN cd /home/node/xen-orchestra && yarn --verbose
RUN cd /home/node/xen-orchestra && yarn build --verbose

COPY link_plugins.sh /home/node/xen-orchestra/packages/xo-server/link_plugins.sh
RUN /home/node/xen-orchestra/packages/xo-server/link_plugins.sh

FROM alpine:3.11

ENV USER=node \
    XOA_PLAN=5 \
    DEBUG=xo:main

## Add a user
RUN mkdir -p /home/node

WORKDIR /home/node

RUN apk add --no-cache \
  su-exec \
  bash \
  util-linux \
  nfs-utils \
  lvm2 \
  fuse \
  gettext \
  cifs-utils \
  openssl

COPY --from=build /home/node/xen-orchestra /home/node/xen-orchestra

COPY --from=build /usr/local/bin/node /usr/bin/
COPY --from=build /usr/lib/libgcc* /usr/lib/libstdc* /usr/lib/

WORKDIR /home/node/xen-orchestra/packages/xo-server/

ENTRYPOINT ["./bin/xo-server"]
