FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential wget tar xz-utils golang-go perl \
        ca-certificates liblz4-dev libbrotli-dev libpcre2-dev libpcre3-dev libzstd-dev libgtest-dev \
        libusb-1.0.0-dev libssl-dev protobuf-compiler libprotobuf-dev lsusb

RUN wget -q --show-progress --progress=bar:force https://cmake.org/files/v3.16/cmake-3.16.3.tar.gz \
    && tar -xvf cmake-3.16.3.tar.gz && rm cmake-3.16.3.tar.gz \
    && cd cmake-3.16.3 \
    && ./configure && make -j 12 && make install \
    && cd ..

ARG RELEASE="31.0.3p1"
RUN wget -q --show-progress --progress=bar:force https://github.com/nmeum/android-tools/releases/download/${RELEASE}/android-tools-${RELEASE}.tar.xz \
    && tar -xvf android-tools-${RELEASE}.tar.xz && rm android-tools-${RELEASE}.tar.xz \
    && mv android-tools-${RELEASE} android-tools

RUN mkdir android-tools/build && cd android-tools/build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j 12

RUN rm -rf cmake-3.16.3 \
    && apt-get remove --purge --auto-remove build-essential wget tar xz-utils golang-go perl liblz4-dev \
        libbrotli-dev libpcre2-dev libpcre3-dev libzstd-dev libgtest-dev libusb-1.0.0-dev libssl-dev \
        protobuf-compiler libprotobuf-dev

RUN ln -sr android-tools/build/vendor/adb /usr/local/bin/adb

RUN adduser --disabled-login --disabled-password adb
USER adb
CMD ["/usr/local/bin/adb", "-a", "nodaemon", "server"]