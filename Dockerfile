FROM quay.io/homdx/qt-android-docker as builder-arm

#Sea branch master for build linux Qt from dev branch before build this
#After build from master you can change tag FROM you image or use prebuild image

COPY clean-git.sh /

RUN export QT_HOST_BUILD=/6.0.0 && export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:/6.0.0/bin:$PATH && env && cd /qt5 && time ./configure -qt-host-path $QT_HOST_BUILD -debug -release -opensource -confirm-license -release -nomake tests -nomake examples -android-sdk $ANDROID_SDK_ROOT -android-ndk $ANDROID_NDK_HOME -xplatform android-clang -no-warnings-are-errors -openssl -I$OPENSSL_ROOT_DIR/include -L$OPENSSL_ROOT_DIR/lib -android-abis armeabi-v7a -- -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR \
   --prefix=/6.0.0/armv7 && time make -j3 && time make install && time sh /clean-git.sh && echo done build qt dev for armv7

FROM debian:10

RUN apt-get update && apt-get upgrade -y
COPY --from=builder2 /usr/local /usr/local

ARG NDK_VERSION=r21b
ARG SDK_INSTALL_PARAMS=platform-tool,build-tools-28.0.3
ARG ANDROID_SDK_ROOT=/android-sdk-linux

MAINTAINER HomDX

RUN apt-get install -y \
    wget \
    curl \
    unzip \
    git \
    make \
    time \
    && apt-get clean \
    && \
    apt install apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common -y \
        && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
        && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
        && apt update && apt install adoptopenjdk-8-hotspot -y \
        && apt-get clean

RUN wget https://raw.githubusercontent.com/homdx/qtci/513/bin/install-android-sdk --directory-prefix=/tmp \
    &&  chmod u+rx /tmp/install-android-sdk \
    && /tmp/install-android-sdk $SDK_INSTALL_PARAMS

RUN    cd /android-sdk-linux/tools/bin \
    && ./sdkmanager  "build-tools;28.0.3" \
    && ./sdkmanager "platforms;android-28"

COPY --from=builder-arm /6.0.0 /6.0.0
COPY --from=builder-arm /android_ssl_1.1.1i /android_ssl_1.1.1i

ENV ANDROID_SDK_ROOT=/android-sdk-linux
ENV NDK_VERSION=r21b
ENV ANDROID_NDK_HOME=/android-ndk-r21b
ENV PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH 
ENV OPENSSL_ROOT_DIR=/android_ssl_1.1.1i
ENV PATH=/6.0.0/armv7/bin:/6.0.0/bin:$PATH

CMD tail -f /var/log/*
