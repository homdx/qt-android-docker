#!/bin/bash

export QT_VERSION=5.13.2
echo start build script
echo QT version is $QT_VERSION
echo show envs in build script
set
export PATH="/Qt/$QT_VERSION/android_armv7/bin/:${PATH}"
echo show new envs in build script
set
export QT_HOME=/qt-everywhere-src-$QT_VERSION
#/Qt5132/Qt/$QT_VERSION/
echo search whereis
whereis qmake

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
cd $QT_HOME && echo start build && date && LANG=C ./configure -recheck -android-arch armeabi-v7a -opensource -confirm-license -release -nomake tests -nomake examples -no-compile-examples -android-sdk /android-sdk-linux -android-ndk /android-ndk-r19c -xplatform android-clang -no-warnings-are-errors --disable-rpath \
-openssl -I /android_openssl/openssl-1.1.1d/include -L /android_openssl/arm \
-prefix /usr/local/armv7 && \
make --no-print-directory && echo end build && date && echo build done && make install && cd $QT_HOME/qtbase/src/tools/androiddeployqt && make && make install &&  echo done1 && date && echo rm -rf /Qt && date && echo all done ok || echo error build
