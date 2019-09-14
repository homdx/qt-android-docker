FROM debian:latest

ARG QT_VERSION=5.13.1
ARG NDK_VERSION=r19c
ARG SDK_INSTALL_PARAMS=platform-tool,build-tools-28.0.2,android-21
ARG QT_PACKAGES="qt,qt.qt5.5131,qt.qt5.5131.gcc_64,qt.qt5.5131.android_armv7"
ARG ANDROID_SDK_ROOT=/android-sdk-linux

MAINTAINER HomDX

RUN dpkg --add-architecture i386
RUN apt-get update

RUN apt-get install -y \
	wget \
	curl \
	unzip \
	git \
	make \
	lib32z1 \
	lib32ncurses6 \
	libbz2-1.0:i386 \
	lib32stdc++6 \
	&& apt-get clean

#install dependencies for Qt installer
RUN apt-get install -y \
	libgl1-mesa-glx \
	libglib2.0-0 \
	&& apt-get clean

#install dependencies for Qt modules
RUN apt-get install -y \
	libfontconfig1 \
	libdbus-1-3 \
	libx11-xcb1 \
	libnss3-dev \
	libasound2-dev \
	libxcomposite1 \
	libxrandr2 \
	libxcursor-dev \
	libegl1-mesa-dev \
	libxi-dev \
	libxss-dev \
	libxtst6 \
	libgl1-mesa-dev \
	&& apt install apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common -y \
        && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add - \
        && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
        && apt update && apt install adoptopenjdk-8-hotspot -y \
        && apt-get clean

#Install CLANG
RUN     wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
	&& apt-add-repository --yes  "deb http://apt.llvm.org/buster/ llvm-toolchain-buster main" \
	&& apt update && apt list --upgradable && apt-get upgrade -y && apt install clang-3.9 lldb -y \
        && apt-get clean

ENV VERBOSE=1
ENV QT_CI_PACKAGES=$QT_PACKAGES

#COPY install-android-sdk /tmp/install-android-sdk
RUN wget https://raw.githubusercontent.com/homdx/qtci/513/bin/install-android-sdk --directory-prefix=/tmp \
	&&  chmod u+rx /tmp/install-android-sdk \
	&& /tmp/install-android-sdk $SDK_INSTALL_PARAMS

#dependencies for Qt installer
RUN apt-get install -y \
       libgl1-mesa-glx \
       libglib2.0-0 \
       && apt-get clean

ARG QT_VERSION=5.13.1
ARG NDK_VERSION=r19c
ARG ANDROID_SDK_ROOT=/android-sdk-linux

ARG PATH="/Qt/$QT_VERSION/android_armv7/bin/:${PATH}"
ARG ANDROID_NDK_ROOT="/android-ndk-$NDK_VERSION"
ARG ANDROID_SDK_ROOT="/android-sdk-linux"
ARG QT_HOME=/Qt/$QT_VERSION/

RUN apt install build-essential g++ -y && \
apt-get install gcc git bison python gperf pkg-config gdb-multiarch -y && \
apt-get install libgles2-mesa-dev -y && \
export NDK_VERSION=r19c && \
export    ANDROID_NDK_ARCH=arch-arm c && \
export    ANDROID_NDK_EABI=llvm c && \ 
export    ANDROID_NDK_HOST=linux-x86_64 c && \
export    ANDROID_NDK_TOOLCHAIN_PREFIX=arm-linux-androideabi c && \
export    ANDROID_NDK_TOOLCHAIN_VERSION=4.9 c && \
export DEBIAN_FRONTEND=noninteractive c && \
cd /Qt/5.13.1/Src && echo start build && date && ./configure -android-arch armeabi-v7a -opensource -confirm-license -release -nomake tests -nomake examples -no-compile-examples -android-sdk /android-sdk-linux -android-ndk /android-ndk-r19c -xplatform android-clang -no-warnings-are-errors --disable-rpath && \
make -j4 && echo end build && date && echo build done && make install && cd /Qt/5.13.1/Src/qtbase/src/tools/androiddeployqt && make && make install || echo error build

RUN mkdir -p /usr/local/Qt-5.13.1/android_armv7 && ln -s /usr/local/Qt-5.13.1/bin /usr/local/Qt-5.13.1/android_armv7/bin

ARG QT_VERSION=5.13.1
ENV PATH="/usr/local/$QT_VERSION/android_armv7/bin/:${PATH}"
ENV QT_HOME=/usr/local/$QT_VERSION/

RUN rm -rf /Qt/


#download + install Qt
RUN mkdir -p /tmp/qt-installer \
       cd /tmp/qt-installer \
       && wget https://raw.githubusercontent.com/homdx/qtci/master/bin/extract-qt-installer --directory-prefix=/tmp/qt-installer/ \
       && wget https://raw.githubusercontent.com/homdx/qtci/master/recipes/install-qt --directory-prefix=/tmp/qt-installer/ \
       && export PATH=$PATH:/tmp/qt-installer/ \
       && chmod u+rx /tmp/qt-installer/extract-qt-installer \
       && chmod u+rx /tmp/qt-installer/install-qt \
       && bash /tmp/qt-installer/install-qt $QT_VERSION \
       && rm -rf /tmp/qt-installer && \
apt install build-essential g++ -y && \
apt-get install gcc git bison python gperf pkg-config gdb-multiarch -y && \
apt-get install libgles2-mesa-dev -y && \
export NDK_VERSION=r19c && \
export    ANDROID_NDK_ARCH=arch-arm c && \
export    ANDROID_NDK_EABI=llvm c && \
export    ANDROID_NDK_HOST=linux-x86_64 c && \
export    ANDROID_NDK_TOOLCHAIN_PREFIX=arm-linux-androideabi c && \
export    ANDROID_NDK_TOOLCHAIN_VERSION=4.9 c && \
export DEBIAN_FRONTEND=noninteractive c && \
cd /Qt/5.13.1/Src && echo start build && date && ./configure -android-arch armeabi-v7a -opensource -confirm-license -release -nomake tests -nomake examples -no-compile-examples -android-sdk /android-sdk-linux -android-ndk /android-ndk-r19c -xplatform android-clang -no-warnings-are-errors --disable-rpath && \
make -j4 && echo end build && date && echo build done && make install && cd /Qt/5.13.1/Src/qtbase/src/tools/androiddeployqt && make && make install && echo done1 && date && rm -rf /Qt && date || echo error build

RUN wget https://raw.githubusercontent.com/homdx/qtci/513/bin/build-android-gradle-project --directory-prefix=/root/ \
        && chmod u+rx /root/build-android-gradle-project

ENV PATH="/usr/local/$QT_VERSION/bin/:${PATH}"
ENV ANDROID_NDK_ROOT="/android-ndk-$NDK_VERSION"
ENV ANDROID_SDK_ROOT="/android-sdk-linux"
ENV QT_HOME=/usr/local/$QT_VERSION/

RUN ln -s /root/build-android-gradle-project /usr/bin/build-android-gradle-project

RUN mkdir -pv /usr/local/Qt-5.13.1/android_armv7 && ln -s /usr/local/Qt-5.13.1/bin /usr/local/Qt-5.13.1/android_armv7/bin

CMD tail -f /var/log/faillog
