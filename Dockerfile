FROM fedora:29 as builder

RUN dnf update -y && dnf install gcc unzip wget time aria2 which patch git make xz -y && dnf install gcc-c++ openssl-devel nano mc -y 
#g++ from 30 and later fedora

#RUN cd / &&  git clone git://code.qt.io/qt/qt5.git && cd qt5 && time perl ./init-repository 
RUN ldd --version && sleep 60 && cd / && wget https://github.com/Kitware/CMake/releases/download/v3.19.2/cmake-3.19.2.tar.gz &&  tar -xvf cmake-3.19.2.tar.gz && rm *.tar.gz
RUN cd  cmake-3.19.2 && time ./configure && time make -j4 && time make install && time make clean
RUN cd / &&  git clone git://code.qt.io/qt/qt5.git && cd qt5 && time perl ./init-repository

RUN cd /qt5 && time ./configure -no-opengl && time make -j2 && echo build done && time make install && make clean || echo error build && date

#COPY /build-from-source5140dev.sh /
COPY clean-git.sh /
RUN ls -la /usr/local/bin && ls -la /usr/local && cd /qt5 && time sh /clean-git.sh

FROM debian:10 as builder2

RUN apt-get update && apt-get upgrade -y
COPY --from=builder /usr/local /6.0.0

ARG NDK_VERSION=r21b
ARG SDK_INSTALL_PARAMS=platform-tool,build-tools-28.0.2
ARG ANDROID_SDK_ROOT=/android-sdk-linux

MAINTAINER HomDX

RUN ls -la /6.0.0 && ls -la /6.0.0/bin && apt-get install -y \
    wget \
    curl \
    unzip \
    git \
    make \
    && apt-get clean \
    && \
    apt install apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common -y \
        && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
        && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
        && apt update && apt install adoptopenjdk-8-hotspot -y \
        && apt-get clean

#Install CLANG
#RUN     wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
#    && apt-add-repository --yes  "deb http://apt.llvm.org/buster/ llvm-toolchain-buster main" \
#    && apt update && apt list --upgradable && apt-get upgrade -y && apt install clang-3.9 lldb -y \
#        && apt-get clean

ENV VERBOSE=1
ENV QT_CI_PACKAGES=$QT_PACKAGES

#COPY install-android-sdk /tmp/install-android-sdk
RUN wget https://raw.githubusercontent.com/homdx/qtci/513/bin/install-android-sdk --directory-prefix=/tmp \
    &&  chmod u+rx /tmp/install-android-sdk \
    && /tmp/install-android-sdk $SDK_INSTALL_PARAMS

#dependencies for builder
RUN apt-get install -y \
       time \
       build-essential g++ \
       && apt-get clean

ARG ANDROID_NDK_HOME=/android-ndk-r21b
#ARG PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH 
ARG OPENSSL_ROOT_DIR=/android_ssl_1.1.1i

ARG QT_HOST_PATH=/usr/local

RUN export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH && mkdir openssl && cd openssl && wget --quiet https://www.openssl.org/source/openssl-1.1.1i.tar.gz && tar -xpf ./openssl-1.1.1i.tar.gz \
   && cd ./openssl-1.1.1i && export CC=clang && ./Configure android-arm --prefix=$OPENSSL_ROOT_DIR && mkdir -p $OPENSSL_ROOT_DIR \
   && echo start build openssl arm && make -j4 2>&1 >/dev/null && echo install opensll && make install

COPY --from=builder /qt5 /qt5
ARG ANDROID_SDK_ROOT=/android-sdk-linux
RUN    cd /android-sdk-linux/tools/bin \
    && ./sdkmanager  "build-tools;28.0.3" \
    && ./sdkmanager "platforms;android-28"
RUN ls -la / && export QT_HOST_BUILD=/6.0.0 && export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:/6.0.0/bin:$PATH && env && cd /qt5 && time ./configure -qt-host-path $QT_HOST_BUILD -debug -release -opensource -confirm-license -release -nomake tests -nomake examples -android-sdk $ANDROID_SDK_ROOT -android-ndk $ANDROID_NDK_HOME -xplatform android-clang -no-warnings-are-errors -openssl -I$OPENSSL_ROOT_DIR/include -L$OPENSSL_ROOT_DIR/lib -android-abis armeabi-v7a -- -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR && time make -j3 && time make install

FROM debian:10

RUN apt-get update && apt-get upgrade -y
COPY --from=builder2 /usr/local /usr/local

ARG NDK_VERSION=r21b
ARG SDK_INSTALL_PARAMS=platform-tool,build-tools-28.0.2
ARG ANDROID_SDK_ROOT=/android-sdk-linux

MAINTAINER HomDX

RUN apt-get install -y \
    wget \
    curl \
    unzip \
    git \
    make \
    && apt-get clean \
    && \
    apt install apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common -y \
        && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
        && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
        && apt update && apt install adoptopenjdk-8-hotspot -y \
        && apt-get clean

RUN    cd /android-sdk-linux/tools/bin \
    && ./sdkmanager  "build-tools;28.0.3" \
    && ./sdkmanager "platforms;android-28"

RUN cd / && wget https://github.com/Kitware/CMake/releases/download/v3.19.2/cmake-3.19.2.tar.gz &&  tar -xvf cmake-3.19.2.tar.gz && rm *.tar.gz \
   && cd  cmake-3.19.2 && time ./configure && time make -j4 && time make install && time make clean && cd / && rm -rf /cmake-3.19.2

ENV ANDROID_SDK_ROOT=/android-sdk-linux
ENV NDK_VERSION=r21b
ENV ANDROID_NDK_HOME=/android-ndk-r21b
ENV PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH 
ENV OPENSSL_ROOT_DIR=/android_ssl_1.1.1i

CMD tail -f /var/log/*
