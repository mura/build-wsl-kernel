ARG GCC_VER
FROM gcc:${GCC_VER}

RUN set -eux; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        flex \
        bison \
        libelf-dev \
        bc \
    ; \
    rm -rf /var/lib/apt/lists/*