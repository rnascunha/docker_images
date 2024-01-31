# syntax=docker/dockerfile:1
FROM alpine:latest
WORKDIR /
RUN set -eux; \
    apk add --no-cache --update dnsmasq nfs-utils samba-server
COPY tftpboot/ /tftpboot/
COPY etc/ /etc
COPY --chmod=755 run.alpine.sh /run.sh
ENTRYPOINT [ "/run.sh" ]
# ENTRYPOINT [ "ash" ]