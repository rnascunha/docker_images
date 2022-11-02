# syntax=docker/dockerfile:1
FROM ubuntu:latest
WORKDIR /app
RUN set -eux; \
    apt-get update && \
    apt-get install -y python3 gcc g++ cmake git wget && \
    rm -rf /var/lib/apt/lists/* && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm -f get-pip.py && \
    pip install conan && \
    conan remote add owner https://rnascunha.jfrog.io/artifactory/api/conan/owner-conan && \
    conan config set general.revisions_enabled=1 && \
    conan profile new default --detect && \
    conan profile update settings.compiler=gcc default && \
    conan profile update settings.compiler.libcxx=libstdc++11 default
CMD [ "/bin/bash" ]