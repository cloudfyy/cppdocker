FROM ubuntu:22.10 AS base 
WORKDIR /app

FROM base AS build 
LABEL Description="Build environment"
ENV CMAKE_RELEASE 3.27.0
ENV HOME /root

SHELL ["/bin/bash", "-c"]

RUN apt update && apt -y --no-install-recommends install \
    build-essential \
    gdb \
    wget \
    curl \
    zip \
    unzip \
    tar \
    ca-certificates \
    git \
    pkg-config 
RUN update-ca-certificates
RUN cat /etc/ssl/certs/ca-certificates.crt
RUN wget --no-check-certificate --quiet https://github.com/Kitware/CMake/releases/download/v${CMAKE_RELEASE}/cmake-${CMAKE_RELEASE}-linux-x86_64.tar.gz
RUN test ! -d /opt/cmake && mkdir /opt/cmake 
RUN tar xf cmake-${CMAKE_RELEASE}-linux-x86_64.tar.gz --strip-components=1 -C /opt/cmake
RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake
RUN wget --no-check-certificate --quiet  -O vcpkg.tar.gz https://github.com/microsoft/vcpkg/archive/master.tar.gz \
    && mkdir /opt/vcpkg \
    && tar xf vcpkg.tar.gz --strip-components=1 -C /opt/vcpkg \
    && /opt/vcpkg/bootstrap-vcpkg.sh \
    && ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg \
    && rm -rf vcpkg.tar.gz
RUN vcpkg install boost-filesystem
ADD . /src
WORKDIR /src

RUN cmake -B build --preset default
RUN cmake --build build 

FROM base AS final
WORKDIR /app
COPY --from=build /src/build/cppdocker .
