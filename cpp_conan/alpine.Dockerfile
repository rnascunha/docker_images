# syntax=docker/dockerfile:1
FROM alpine:latest
WORKDIR /app
RUN set -eux; \
    apk add --update --no-cache python3 gcc g++ git cmake make libstdc++ linux-headers perl && \
    python3 -m ensurepip && python3 -m pip install --upgrade pip && \
    pip install conan && \
    conan remote add owner https://rnascunha.jfrog.io/artifactory/api/conan/owner-conan && \
    conan config set general.revisions_enabled=1 && \
    conan profile new default --detect && \
    conan profile update settings.compiler=gcc default && \
    conan profile update settings.compiler.libcxx=libstdc++11 default
CMD [ "/bin/ash" ]