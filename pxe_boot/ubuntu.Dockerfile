# syntax=docker/dockerfile:1
FROM ubuntu:latest
WORKDIR /
RUN set -eux; \
    apt-get update && \
    apt-get install dnsmasq nfs-kernel-server samba -y && \
    apt-get clean
COPY tftpboot/ /tftpboot/
COPY etc_ubuntu/ /etc
COPY --chmod=755 run.ubuntu.sh /run.sh
ENTRYPOINT [ "/run.sh" ]
# ENTRYPOINT [ "bash" ]